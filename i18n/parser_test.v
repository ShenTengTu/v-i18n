module i18n

fn test_re_is_match() ? {
	mut tag_name := 'extlang'
	mut pattern := '^${re_langtag[tag_name]}(-$re_langtag_suffix)?$'

	mut txt := 'sl-rozaj-solba-1994'.all_after('-') // 'rozaj-solba-1994'
	assert false == re_is_match(pattern, txt) ?

	tag_name = 'privateuse'
	pattern = '^${re_langtag[tag_name]}$'
	txt = 'x-private-use'
	assert true == re_is_match(pattern, txt) ?
}

fn test_re_get_named_groups() ? {
	mut tag_name := 'extlang'
	mut pattern := '^${re_langtag[tag_name]}(-$re_langtag_suffix)?$'

	mut txt := 'sl-rozaj-solba-1994'.all_after('-') // 'rozaj-solba-1994'
	mut m := map[string]string{}
	m = re_get_named_groups(pattern, txt, mut m) ?
	assert (tag_name in m) == false
	assert ('suffix' in m) == false

	tag_name = 'privateuse'
	pattern = '^${re_langtag[tag_name]}$'
	txt = 'x-private-use'
	m = re_get_named_groups(pattern, txt, mut m) ?
	assert (tag_name in m) == true

	tag_name = 'language'
	pattern = '^${re_langtag[tag_name]}(-$re_langtag_suffix)?$'
	txt = 'zh'
	m = re_get_named_groups(pattern, txt, mut m) ?
	assert (tag_name in m) == true
	txt = 'zh-cmn'
	m = re_get_named_groups(pattern, txt, mut m) ?
	assert (tag_name in m) == true
}
