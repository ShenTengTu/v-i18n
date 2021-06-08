module tests

import i18n { parse_language_tag }

fn test_parse_language_tag() ? {
	mut with_error := WithError{}

	// grandfathered tag
	mut tag := 'i-default'
	mut l := parse_language_tag(tag) ?
	assert l.is_grandfathered == true
	assert '$l' == tag
	assert l.is_redundant == false
	// Invalid Language-Tag format.
	for t in ['en US', '-en-US', 'en-US-'] {
		parse_language_tag(t) or { with_error = WithError{
			error: err
		} }
		assert (with_error.error is none) == false
		assert with_error.error.code == 1
		with_error = WithError{}
	}

	// Private use tag
	parse_language_tag('x-private-use') or { with_error = WithError{
		error: err
	} }
	assert (with_error.error is none) == false
	assert with_error.error.code == 0
	with_error = WithError{}

	// Parse `language` subtag
	tag = 'zh'
	l = parse_language_tag(tag) ?
	assert tag == l.subtag('language') ?
	assert '$l' == tag
	assert l.is_redundant == false
	tag = 'zh-cmn'
	l = parse_language_tag(tag) ?
	assert tag == l.subtag('language') ?
	assert 'cmn' == l.subtag('extlang') ?
	assert '$l' == tag
	assert l.is_redundant == false
	// Invalid `language` tag format.
	tag = 'Zh-cmn'
	parse_language_tag(tag) or { with_error = WithError{
		error: err
	} }
	assert (with_error.error is none) == false
	assert with_error.error.code == 2
	with_error = WithError{}
	// Deprecated or private use tag.
	for t in ['in', 'ar-bbz'] {
		parse_language_tag(t) or { with_error = WithError{
			error: err
		} }
		assert (with_error.error is none) == false
		assert with_error.error.code == 0
		with_error = WithError{}
	}

	// Parse `script` subtag
	tag = 'zh-Hant'
	l = parse_language_tag(tag) ?
	assert 'zh' == l.subtag('language') ?
	assert 'Hant' == l.subtag('script') ?
	assert '$l' == tag
	assert l.is_redundant == true
	// The tag contains suppress script.
	tag = 'en-Latn'
	parse_language_tag(tag) or { with_error = WithError{
		error: err
	} }
	assert (with_error.error is none) == false
	assert with_error.error.code == 3
	with_error = WithError{}
	// Deprecated or private use tag.
	tag = 'en-Qaaa'
	parse_language_tag(tag) or { with_error = WithError{
		error: err
	} }
	assert (with_error.error is none) == false
	assert with_error.error.code == 0
	with_error = WithError{}
	// Parse `region` subtag
	tag = 'en-US'
	l = parse_language_tag(tag) ?
	assert 'en' == l.subtag('language') ?
	assert 'US' == l.subtag('region') ?
	assert '$l' == tag
	assert l.is_redundant == false
	tag = 'en-001'
	l = parse_language_tag(tag) ?
	assert 'en' == l.subtag('language') ?
	assert '001' == l.subtag('region') ?
	assert '$l' == tag
	assert l.is_redundant == false
	// Deprecated or private use tag.
	tag = 'en-ZZ'
	parse_language_tag(tag) or { with_error = WithError{
		error: err
	} }
	assert (with_error.error is none) == false
	assert with_error.error.code == 0
	with_error = WithError{}
	// language-script-region
	tag = 'aa-Adlm-AC'
	l = parse_language_tag(tag) ?
	assert 'aa' == l.subtag('language') ?
	assert 'Adlm' == l.subtag('script') ?
	assert 'AC' == l.subtag('region') ?
	assert '$l' == tag
	assert l.is_redundant == false

	// Parse `variant` subtag
	tag = 'frm-1606nict'
	l = parse_language_tag(tag) ?
	assert 'frm' == l.subtag('language') ?
	assert '1606nict' == l.subtag('variant') ?
	assert '$l' == tag
	//
	tag = 'de-1901'
	l = parse_language_tag(tag) ?
	assert 'de' == l.subtag('language') ?
	assert '1901' == l.subtag('variant') ?
	assert '$l' == tag
	tag = 'sl-rozaj-solba-1994'
	//
	l = parse_language_tag(tag) ?
	assert 'sl' == l.subtag('language') ?
	assert 'rozaj-solba-1994' == l.subtag('variant') ?
	assert '$l' == tag
	//
	tag = 'pt-BR-abl1943'
	l = parse_language_tag(tag) ?
	assert 'pt' == l.subtag('language') ?
	assert 'BR' == l.subtag('region') ?
	assert 'abl1943' == l.subtag('variant') ?
	assert '$l' == tag
	//
	tag = 'sr-Latn-ekavsk'
	l = parse_language_tag(tag) ?
	assert 'sr' == l.subtag('language') ?
	assert 'Latn' == l.subtag('script') ?
	assert 'ekavsk' == l.subtag('variant') ?
	assert '$l' == tag
	// Invalid variant
	tag = 'en-1694acad' // "fr-1694acad" is valid
	parse_language_tag(tag) or { with_error = WithError{
		error: err
	} }
	assert (with_error.error is none) == false
	assert with_error.error.code == 0
	with_error = WithError{}

	// Parse `extension` tag
	tag = 'en-US-r-extended-sequence'
	l = parse_language_tag(tag) ?
	assert 'en' == l.subtag('language') ?
	assert 'US' == l.subtag('region') ?
	assert 'r-extended-sequence' == l.subtag('extension') ?

	// Private use tag
	tag = 'en-US-r-extended-sequence-x-private-use'
	parse_language_tag(tag) or { with_error = WithError{
		error: err
	} }
	assert (with_error.error is none) == false
	assert with_error.error.code == 0
	with_error = WithError{}

	// Invalid Language-Tag format
	tag = 'en-US-ab-bc-de'
	parse_language_tag(tag) or { with_error = WithError{
		error: err
	} }
	assert (with_error.error is none) == false
	assert with_error.error.code == 1
	with_error = WithError{}
}
