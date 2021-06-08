module i18n

import regex
import i18n.language

const re_langtag_text = r'[\a\A\d]+(\-[\a\A\d]+)*'

const re_langtag_suffix = '(?P<suffix>$re_langtag_text)'

const re_langtag = map{
	'language':   r'(?P<language>\a{2,3})'
	'extlang':    r'(?P<extlang>\a{3})'
	'script':     r'(?P<script>\A\a{3})'
	'region':     r'(?P<region>(\A{2})|(\d{3}))'
	'variant':    r'(?P<variant>(([\a\d]{5,8})|(\d[\a\d]{3}))(\-(([\a\d]{5,8})|(\d[\a\d]{3})))*)'
	'extension':  r'(?P<extension>[\da-wy-z](\-([\a\d]{2,8}))+)'
	'privateuse': r'(?P<privateuse>x(\-([\a\A\d]{1,8}))+)'
}

const parsing_error_message_map = map{
	'deprecated_or_privateuse': 'Deprecated, Private-use, or invalid tag.'
	'invalid_tag_format':       'Invalid Language-Tag format.'
	'invalid_subtag_format':    'Invalid subtag format.'
	'suppress_script':          'The tag contains suppress script.'
}

enum ParsingErrorType {
	deprecated_or_privateuse
	invalid_tag_format
	invalid_subtag_format
	suppress_script
}

fn parsing_error(t ParsingErrorType, extra_info string) IError {
	msg := i18n.parsing_error_message_map['$t']
	return error_with_code('$msg $extra_info', int(t))
}

fn set_string_fields_from_map<T>(t T, m map[string]string) T {
	for name, v in m {
		$for field in T.fields {
			if field.name == name && field.is_mut {
				$if field.typ is string {
					t.$(field.name) = v
				}
			}
		}
	}
	return t
}

// Regex : get result of nameed groups
fn re_get_named_groups(pattern string, txt string, mut m map[string]string) ?map[string]string {
	mut re := regex.regex_opt(pattern) or { return err }
	start, _ := re.match_string(txt)
	if start >= 0 {
		for k in re.group_map.keys() {
			m[k] = re.get_group_by_name(txt, k)
		}
	}
	return m
}

// Regex : check if the string matches the pattern
fn re_is_match(pattern string, txt string) ?bool {
	mut re := regex.regex_opt(pattern) or { return err }
	start, _ := re.match_string(txt)
	return start >= 0
}

// Parse IETF BCP 47 language tag to `Locale`
// Not support deprecated & private use tag
pub fn parse_language_tag(tag string) ?Locale {
	// Language tag format:
	// language[-script][-region]*(-variant)*(-extension)[-privateuse]
	sep := '-'
	tag_ := tag.replace('_', sep)

	// Check if it is grandfathered tag
	if tag_ in language.grandfathereds {
		return Locale{
			grandfathered: tag_
			is_grandfathered: true
		}
	}

	is_redundant := tag_ in language.redundants

	if !re_is_match('^$i18n.re_langtag_text$', tag_) ? {
		return parsing_error(.invalid_tag_format, '')
	}

	// Anonymous function for paring tag or subtag
	parse_tag := fn (txt string, tag_name string, is_subtag bool, mut m map[string]string) ?map[string]string {
		mut pattern := ''
		if is_subtag {
			pattern = '^${i18n.re_langtag[tag_name]}(-$i18n.re_langtag_suffix)?$'
		} else {
			pattern = '^${i18n.re_langtag[tag_name]}$'
		}
		return re_get_named_groups(pattern, txt, mut m)
	}

	mut m := map[string]string{}
	mut tag_name := ''

	// Check if it is privateuse tag
	tag_name = 'privateuse'
	m = parse_tag(tag_, tag_name, false, mut m) ?
	if tag_name in m {
		return parsing_error(.deprecated_or_privateuse, '($tag_name: ${m[tag_name]})')
	}

	// Parse `language` subtag
	tag_name = 'language'
	m = parse_tag(tag_, tag_name, true, mut m) ?
	if tag_name !in m {
		return parsing_error(.invalid_subtag_format, '($tag_name)')
	}
	// Check avliable `language` subtag
	if m[tag_name] !in language.languages {
		return parsing_error(.deprecated_or_privateuse, '($tag_name: ${m[tag_name]})')
	}
	// Check avliable `language` subtag
	if m['suffix'] == '' { // There are no subtags to parse, return `Locale`
		return set_string_fields_from_map(Locale{ is_redundant: is_redundant }, m)
	}

	mut pre_suffix := m['suffix'] // after `language` subtag

	// Parse `extlang` subtag
	tag_name = 'extlang'
	m = parse_tag(pre_suffix, tag_name, true, mut m) ?
	if tag_name in m {
		m['language'] += '-${m[tag_name]}'
		if m['language'] !in language.extlangs { // Check avliable `language` subtag (with 'extlang')
			return parsing_error(.deprecated_or_privateuse, '($tag_name: ${m[tag_name]})')
		}
		if m['suffix'] == '' { // There are no subtags to parse, return `Locale`
			return set_string_fields_from_map(Locale{ is_redundant: is_redundant }, m)
		}
		pre_suffix = m['suffix'] // after `extlang` subtag
	}

	// Parse `script` subtag
	tag_name = 'script'
	m = parse_tag(pre_suffix, tag_name, true, mut m) ?
	if tag_name in m {
		// Check if it is a suppression script
		if m['language'] in language.suppress_scripts {
			if m[tag_name] == language.suppress_scripts[m['language']] {
				return parsing_error(.suppress_script, '')
			}
		}
		// Check avliable `script` subtag
		if m[tag_name] !in language.scripts {
			return parsing_error(.deprecated_or_privateuse, '($tag_name: ${m[tag_name]})')
		}
		if m['suffix'] != '' {
			pre_suffix = m['suffix'] // afater `script` subtag
		}
	}

	// Parse `region` subtag
	tag_name = 'region'
	m = parse_tag(pre_suffix, tag_name, true, mut m) ?
	// There are no subtags to parse, return `Locale`
	if tag_name in m {
		if m[tag_name] !in language.regions {
			return parsing_error(.deprecated_or_privateuse, '($tag_name: ${m[tag_name]})')
		}
		if m['suffix'] != '' {
			pre_suffix = m['suffix'] // afater `region` subtag
		}
	}

	// Parse `variant` subtag
	tag_name = 'variant'
	m = parse_tag(pre_suffix, tag_name, true, mut m) ?
	if tag_name in m {
		if tag_ !in language.variants {
			return parsing_error(.deprecated_or_privateuse, '($tag_name: ${m[tag_name]})')
		}
		if m['suffix'] != '' {
			pre_suffix = m['suffix'] // afater `variant` subtag
		}
	}

	// Parse `extension` tag
	tag_name = 'extension'
	m = parse_tag(pre_suffix, tag_name, true, mut m) ?
	if tag_name in m {
		if m['suffix'] != '' {
			pre_suffix = m['suffix'] // afater `variant` subtag
		}
	}

	// Check if it is privateuse tag
	tag_name = 'privateuse'
	m = parse_tag(pre_suffix, tag_name, true, mut m) ?
	if tag_name in m {
		return parsing_error(.deprecated_or_privateuse, '($tag_name: ${m[tag_name]})')
	}

	// There are no subtags to parse, return `Locale`
	if m['suffix'] == '' {
		return set_string_fields_from_map(Locale{ is_redundant: is_redundant }, m)
	}

	return parsing_error(.invalid_tag_format, 'tag: $tag_')
}
