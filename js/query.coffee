'use strict'

app = angular.module 'anyRhymeApp'

app.factory "Query", ($http,$q,anywhere_url) ->
	create_query = (word,original_options) ->
		if (original_options.level == 2)
			options = original_options
		else if (original_options.level == 1) && (original_options.match_type == "port1")
			options = preset_portmanteau1(word,original_options)
		else if (original_options.level == 1) && (original_options.match_type == "port2")
			options = preset_portmanteau2(word,original_options)
		else
			options = preset_rhyme(word,original_options)
		syllables_str = ""
		if options.match_end == "final"
			for i in [(3-options.match_num_syllables)...3]
				s = options.syllables_to_match[i]
				if s.onset.match_type == "match"
					onset = s.onset.label
				else
					onset = "~" + s.onset.label
				if s.nucleus.match_type == "match"
					nucleus = s.nucleus.label
				else
					nucleus = "~" + s.nucleus.label
				if s.coda.match_type == "match"
					coda = s.coda.label
				else
					coda = "~" + s.coda.label
				syllables_str = syllables_str + "/" + onset + "," + nucleus + s.stress + "," + coda
			if matching_end_syllable("leading",options)
				s = options.leading_syllable_to_match
				if s.onset.match_type == "match"
					onset = s.onset.label
				else
					onset = "~" + s.onset.label
				if s.nucleus.match_type == "match"
					nucleus = s.nucleus.label
				else
					nucleus = "~" + s.nucleus.label
				if s.coda.match_type == "match"
					coda = s.coda.label
				else
					coda = "~" + s.coda.label
				end_str = "/" + onset + "," + nucleus + s.stress + "," + coda + "/and"
			else
				end_str = ""
			direction = "beginning"
		else
			for i in [0...options.match_num_syllables]
				s = options.syllables_to_match[2-i]
				if s.onset.match_type == "match"
					onset = s.onset.label
				else
					onset = "~" + s.onset.label
				if s.nucleus.match_type == "match"
					nucleus = s.nucleus.label
				else
					nucleus = "~" + s.nucleus.label
				if s.coda.match_type == "match"
					coda = s.coda.label
				else
					coda = "~" + s.coda.label
				syllables_str = syllables_str + "/" + onset + "," + nucleus + s.stress + "," + coda
			if matching_end_syllable("trailing",options)
				s = options.trailing_syllable_to_match
				if s.onset.match_type == "match"
					onset = s.onset.label
				else
					onset = "~" + s.onset.label
				if s.nucleus.match_type == "match"
					nucleus = s.nucleus.label
				else
					nucleus = "~" + s.nucleus.label
				if s.coda.match_type == "match"
					coda = s.coda.label
				else
					coda = "~" + s.coda.label
				end_str = "/" + onset + "," + nucleus + s.stress + "," + coda + "/and"
			else
				end_str = ""
			direction = "ending"
		if (options.level == 1) && (options.match_length == true) && (options.match_type == "rhyme")
			num_type = "exactly"
			num = 0
		else if (options.level == 2)
			num_type = options.filter_num_syllables_type
			num = options.filter_num_syllables - options.match_num_syllables 
			if matching_end_syllable("trailing",options)
				num = num - 1
			else if matching_end_syllable("leading",options)
				num = num - 1
		else
			num_type = "at-least"
			num = 0
		"match/" + direction + "/with" + end_str + "/" + num_type + "/" + num + "/syllables/and" + syllables_str + ".json"
	query_parameters = (options) ->
		if (options.level > 0) && (options.must_contain_lexemes == false)
			""
		else
			"?defined=true"
	expanded_parameters = (options,offset) ->
		if (options.level > 0) && (options.must_contain_lexemes == false)
			"?offset=" + offset
		else
			"?defined=true&offset=" + offset
	matching_end_syllable = (type,options) ->
		more_syllables = options.filter_num_syllables > options.match_num_syllables
		if (options.match_end == "final")
			type=="leading" && more_syllables
		else
			type=="trailing" && more_syllables
	last_stressed_syllable = (word) -> 
		stresses = word.syllables.map (s) -> (s.stress > 0)
		stresses.length - 1 - stresses.reverse().indexOf(true)
	clear_syllables_to_match = (options) ->
		options.syllables_to_match = [
			blank_syllable(),
			blank_syllable(),
			blank_syllable()
		]
	blank_syllable = () ->
		{
			onset: {match_type: 'match', label: '*'},
			nucleus: {match_type: 'match', label: '*'},
			coda: {match_type: 'match', label: '*'},
			stress: ''
		}
	initialise_options = () ->
		options = {}
		options.level = 0
		options.match_length = false
		options.must_contain_lexemes = true
		options.match_type = "rhyme"
		options.filter_num_syllables_type = "at-least"
		options.filter_num_syllables = 1
		options.match_end = "final"
		options.match_num_syllables = 1
		clear_syllables_to_match(options)
		options.leading_syllable_to_match = blank_syllable()
		options.trailing_syllable_to_match = blank_syllable()
		options
	preset_rhyme = (word,options) ->
		new_options = angular.copy(options)
		clear_syllables_to_match(new_options)
		num = word.syllables.length - last_stressed_syllable(word)
		if num > 3
			num = 3
		for i in [0...num]
			s = word.syllables[word.syllables.length - 1 - i]
			if (i==(num-1)) || (i==2)
				onset_match_type = 'antimatch'
			else
				onset_match_type = 'match'
			if s.stress > 0
				stress_to_match = '3'
			else
				stress_to_match = '0'
			if s.onset == ""
				onset_label = "_"
			else
				onset_label = s.onset.join("-")
			if s.coda == ""
				coda_label = "_"
			else
				coda_label = s.coda.join("-")
			syllable_to_match = {
				onset: { match_type: onset_match_type, label: onset_label },
				nucleus: { match_type: 'match', label: s.nucleus[0] },
				coda: { match_type: 'match', label: coda_label },
				stress: stress_to_match
    	}
			new_options.syllables_to_match[2-i] = syllable_to_match
		new_options.match_num_syllables = num
		new_options.match_end = "final"
		new_options.filter_num_syllables_type = "at-least"
		new_options.filter_num_syllables = 1
		new_options
	preset_portmanteau1 = (word,options) ->
		new_options = angular.copy(options)
		clear_syllables_to_match(new_options)
		s = word.syllables[word.syllables.length-1]
		if s.onset == ""
			onset_label = "_"
		else
			onset_label = s.onset.join("-")
		if s.coda == ""
			coda_label = "_"
		else
			coda_label = s.coda.join("-")
		syllable_to_match = {
			onset: { match_type: 'match', label: onset_label },
			nucleus: { match_type: 'match', label: s.nucleus[0] },
			coda: { match_type: 'match', label: coda_label },
			stress: ''
  	}
		new_options.syllables_to_match[2] = syllable_to_match
		new_options.match_num_syllables = 1
		new_options.match_end = "first"
		new_options.filter_num_syllables_type = "at-least"
		new_options.filter_num_syllables = 2
		new_options
	preset_portmanteau2 = (word,options) ->
		new_options = angular.copy(options)
		clear_syllables_to_match(new_options)
		s = word.syllables[0]
		if s.onset == ""
			onset_label = "_"
		else
			onset_label = s.onset.join("-")
		if s.coda == ""
			coda_label = "_"
		else
			coda_label = s.coda.join("-")
		syllable_to_match = {
			onset: { match_type: 'match', label: onset_label },
			nucleus: { match_type: 'match', label: s.nucleus[0] },
			coda: { match_type: 'match', label: coda_label },
			stress: ''
  	}
		new_options.syllables_to_match[2] = syllable_to_match
		new_options.match_num_syllables = 1
		new_options.match_end = "final"
		new_options.filter_num_syllables_type = "at-least"
		new_options.filter_num_syllables = 2
		new_options
	parse_response = (response) ->
		response.data.map (r) ->
			r.any_lexemes = r.lexemes.length > 0
			r
	execute_query = (word,options) ->
		url = anywhere_url + create_query(word,options) + query_parameters(options)
		if sessionStorage[url] == undefined
			$http({method: 'GET', url: url, cache: true}).then (response) ->
				results = {
					list: parse_response(response)
					exhausted: false
				}
				if results.list.length < 100
					results.exhausted = true
				sessionStorage[url] = JSON.stringify(results)
				results
		else
			$q.when(JSON.parse(sessionStorage[url]))
	expand_query = (word,options) ->
		url = anywhere_url + create_query(word,options) + query_parameters(options)
		if sessionStorage[url] != undefined
			cached_results = JSON.parse(sessionStorage[url])
			if !cached_results.exhausted
				expand_url = anywhere_url + create_query(word,options) + expanded_parameters(options,cached_results.list.length)
				$http({method: 'GET', url: expand_url, cache: true}).then (response) ->
					new_results = parse_response(response)
					if new_results.length < 100
						cached_results.exhausted = true
					cached_results.list = cached_results.list.concat(new_results)
					sessionStorage[url] = JSON.stringify(cached_results)
					cached_results
			else
				$q.when(cached_results)
		else
			$q.when(undefined)
	{
		execute: execute_query,
		expand: expand_query,
		initialise_options: initialise_options,
		matching_end_syllable: matching_end_syllable,
		clear_syllables_to_match: clear_syllables_to_match,
		preset_rhyme: preset_rhyme,
		preset_portmanteau1: preset_portmanteau1,
		preset_portmanteau2: preset_portmanteau2
	}
