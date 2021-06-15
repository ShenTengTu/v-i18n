module i18n

struct Locale {
mut:
	grandfathered string
	language      string
	extlang       string
	script        string
	region        string
	variant       string
	extension     string
	territory     string
	codeset       string = 'UTF-8'
pub:
	is_grandfathered bool
	is_redundant     bool
}

pub fn (l Locale) str() string {
	return l.identifier()
}

// Identifier for POSIX platform. Not include modifier.
pub fn (l Locale) posix_identifier() string {
	// language[_territory[.codeset]]
	mut s := l.language.before('-')
	if l.territory.len > 0 {
		s += '_$l.territory'
		if l.codeset.len > 0 {
			s += '.$l.codeset'
		}
	}
	return s
}

// IETF BCP 47 language tag. Not support privateuse tag.
pub fn (l Locale) identifier() string {
	// language[-script][-region]*(-variant)*(-extension)
	if l.is_grandfathered {
		return l.grandfathered
	}
	mut s := l.language
	if l.script.len > 0 {
		s += '-$l.script'
	}
	if l.region.len > 0 {
		s += '-$l.region'
	}
	if l.variant.len > 0 {
		s += '-$l.variant'
	}
	return s
}

// Set codeset
pub fn (mut l Locale) set_codeset(codeset string) Locale {
	l.codeset = codeset.to_upper()
	return l
}

// Get the value of one of the following subtags:
// `language`, `extlang`, `script`, `region`, `extension`
pub fn (mut l Locale) subtag(name string) ?string {
	match name {
		'language' {
			return l.language
		}
		'extlang' {
			return l.extlang
		}
		'script' {
			return l.script
		}
		'region' {
			return l.region
		}
		'variant' {
			return l.variant
		}
		'extension' {
			return l.extension
		}
		else {
			return error('Invalid subtag name.')
		}
	}
}
