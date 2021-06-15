module tests

import i18n { parse_language_tag }

fn test_parse_language_tag() ? {
	// grandfathered tag
	mut tag := 'i-default'
	mut l := parse_language_tag(tag) ?
	assert l.is_grandfathered == true
	assert '$l' == tag
	assert l.is_redundant == false
	// Invalid Language-Tag format.
	for t in ['en US', '-en-US', 'en-US-'] {
		if _ := parse_language_tag(t) {
			return error('expected an error.')
		} else {
			assert err.code == 1
		}
	}

	// Private use tag
	if _ := parse_language_tag('x-private-use') {
		return error('expected an error.')
	} else {
		assert err.code == 0
	}

	// Parse `language` subtag
	tag = 'zh'
	l = parse_language_tag(tag) ?
	assert tag == l.subtag('language') ?
	assert '$l' == tag
	assert l.is_redundant == false
	assert l.posix_identifier() == 'zh'
	tag = 'zh-cmn'
	l = parse_language_tag(tag) ?
	assert tag == l.subtag('language') ?
	assert 'cmn' == l.subtag('extlang') ?
	assert '$l' == tag
	assert l.is_redundant == false
	assert l.posix_identifier() == 'zh'
	// Invalid `language` tag format.
	tag = 'Zh-cmn'
	if _ := parse_language_tag(tag) {
		return error('expected an error.')
	} else {
		assert err.code == 2
	}
	// Deprecated or private use tag.
	for t in ['in', 'ar-bbz'] {
		if _ := parse_language_tag(t) {
			return error('expected an error.')
		} else {
			assert err.code == 0
		}
	}

	// Parse `script` subtag
	tag = 'zh-Hant'
	l = parse_language_tag(tag) ?
	assert 'zh' == l.subtag('language') ?
	assert 'Hant' == l.subtag('script') ?
	assert '$l' == tag
	assert l.is_redundant == true
	assert l.posix_identifier() == 'zh'
	// The tag contains suppress script.
	tag = 'en-Latn'
	if _ := parse_language_tag(tag) {
		return error('expected an error.')
	} else {
		assert err.code == 3
	}
	// Deprecated or private use tag.
	tag = 'en-Qaaa'
	if _ := parse_language_tag(tag) {
		return error('expected an error.')
	} else {
		assert err.code == 0
	}
	// Parse `region` subtag
	tag = 'en-US'
	l = parse_language_tag(tag) ?
	assert 'en' == l.subtag('language') ?
	assert 'US' == l.subtag('region') ?
	assert '$l' == tag
	assert l.is_redundant == false
	assert l.posix_identifier() == 'en_US.UTF-8'
	tag = 'en-001'
	l = parse_language_tag(tag) ?
	assert 'en' == l.subtag('language') ?
	assert '001' == l.subtag('region') ?
	assert '$l' == tag
	assert l.is_redundant == false
	assert l.posix_identifier() == 'en_001.UTF-8'
	// Deprecated or private use tag.
	tag = 'en-ZZ'
	if _ := parse_language_tag(tag) {
		return error('expected an error.')
	} else {
		assert err.code == 0
	}
	// language-script-region
	tag = 'aa-Adlm-AC'
	l = parse_language_tag(tag) ?
	assert 'aa' == l.subtag('language') ?
	assert 'Adlm' == l.subtag('script') ?
	assert 'AC' == l.subtag('region') ?
	assert '$l' == tag
	assert l.is_redundant == false
	assert l.posix_identifier() == 'aa_AC.UTF-8'
	// Parse `variant` subtag
	tag = 'frm-1606nict'
	l = parse_language_tag(tag) ?
	assert 'frm' == l.subtag('language') ?
	assert '1606nict' == l.subtag('variant') ?
	assert '$l' == tag
	assert l.posix_identifier() == 'frm'
	//
	tag = 'de-1901'
	l = parse_language_tag(tag) ?
	assert 'de' == l.subtag('language') ?
	assert '1901' == l.subtag('variant') ?
	assert '$l' == tag
	assert l.posix_identifier() == 'de'
	//
	tag = 'sl-rozaj-solba-1994'
	l = parse_language_tag(tag) ?
	assert 'sl' == l.subtag('language') ?
	assert 'rozaj-solba-1994' == l.subtag('variant') ?
	assert '$l' == tag
	assert l.posix_identifier() == 'sl'
	//
	tag = 'pt-BR-abl1943'
	l = parse_language_tag(tag) ?
	assert 'pt' == l.subtag('language') ?
	assert 'BR' == l.subtag('region') ?
	assert 'abl1943' == l.subtag('variant') ?
	assert '$l' == tag
	assert l.posix_identifier() == 'pt_BR.UTF-8'
	//
	tag = 'sr-Latn-ekavsk'
	l = parse_language_tag(tag) ?
	assert 'sr' == l.subtag('language') ?
	assert 'Latn' == l.subtag('script') ?
	assert 'ekavsk' == l.subtag('variant') ?
	assert '$l' == tag
	assert l.posix_identifier() == 'sr'
	// Invalid variant
	tag = 'en-1694acad' // "fr-1694acad" is valid
	if _ := parse_language_tag(tag) {
		return error('expected an error.')
	} else {
		assert err.code == 0
	}

	// Parse `extension` tag
	tag = 'en-US-r-extended-sequence'
	l = parse_language_tag(tag) ?
	assert 'en' == l.subtag('language') ?
	assert 'US' == l.subtag('region') ?
	assert 'r-extended-sequence' == l.subtag('extension') ?
	assert l.posix_identifier() == 'en_US.UTF-8'
	// Private use tag
	tag = 'en-US-r-extended-sequence-x-private-use'
	if _ := parse_language_tag(tag) {
		return error('expected an error.')
	} else {
		assert err.code == 0
	}

	// Invalid Language-Tag format
	tag = 'en-US-ab-bc-de'
	if _ := parse_language_tag(tag) {
		return error('expected an error.')
	} else {
		assert err.code == 1
	}
}
