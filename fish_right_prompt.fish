function fish_right_prompt
  set -l path_timestamp '/tmp/ika_timestamp.txt'
  set -l path_schedule '/tmp/ika_schedule.json'
  set -l path_fes '/tmp/ika_fes.json'
  set -l path_salmon '/tmp/ika_salmon.json'
  set -l path_geso '/tmp/ika_geso.json'
  set -l json_path_list $path_schedule $path_fes $path_salmon $path_geso

  _needs_update $path_timestamp $json_path_list
  and _update_json_async $path_timestamp $json_path_list
  and return 0

  set -l output ''
  if _can_i_fes $path_fes
    set output (_translate "fes")
  else
    set -l rule_key_gachi (_current_gachi_rule $path_schedule)
    set -l rule_key_league (_current_league_rule $path_schedule)
    
    set -l rule_name_gachi (_translate $rule_key_gachi)
    if test $status -eq 1
      return 0
    end
    
    set -l rule_name_league (_translate $rule_key_league)
    if test $status -eq 1
      return 0
    end

    set -l output_list $rule_name_gachi $rule_name_league
    if _can_i_work $path_salmon
      set output_list (_translate "coop") $output_list
    end

    set output (string join "|" $output_list)
  end

  set_color $fish_color_autosuggestion ^/dev/null; or set_color 555
  echo $output
  set_color normal
end

function _needs_update --argument-names path_timestamp
  test ! -e $path_timestamp  # timestamp file is not existed
  or test ! -e $argv[2]; or test ! -s $argv[2] # not existed or empty (caused by network error)
  or test ! -e $argv[3]; or test ! -s $argv[3]
  or test ! -e $argv[4]; or test ! -s $argv[4]
  or test ! -e $argv[5]; or test ! -s $argv[5]
  or test (math (date "+%s") - (cat $path_timestamp)) -ge (math 60 \* 60 \* 12) # cache 12h
end

function _update_json_async --argument-names path_timestamp path_schedule path_fes path_salmon path_geso
  set -l api_endpoint_schedule 'https://splatoon2.ink/data/schedules.json'
  set -l api_endpoint_fes 'https://splatoon2.ink/data/festivals-na.json'
  set -l api_endpoint_salmon 'https://splatoon2.ink/data/salmonruncalendar.json'
  set -l api_endpoint_geso 'https://splatoon2.ink/data/merchandises.json'
  fish -c "curl -s $api_endpoint_schedule > $path_schedule" &
  fish -c "curl -s $api_endpoint_fes > $path_fes" &
  fish -c "curl -s $api_endpoint_salmon > $path_salmon" &
  fish -c "curl -s $api_endpoint_geso > $path_geso" &
  command date "+%s" > $path_timestamp
end

function _can_i_fes --argument-names path_fes
  set -l current_time (date "+%s")
  command cat $path_fes | jq -e -r ".festivals[] | select(.times.start < $current_time) | select(.times.end > $current_time)" > /dev/null ^ /dev/null
end

function _can_i_work --argument-names path_salmon
  set -l current_time (date "+%s")
  command cat $path_salmon | jq -e -r ".schedules[] | select(.start_time < $current_time) | select(.end_time > $current_time)" > /dev/null ^ /dev/null
end

function _current_fes_name --argument-names path_fes
  set -l current_time (date "+%s")
  echo (command cat $path_fes | jq -r ".festivals[] | select(.times.start < $current_time) | select(.times.end > $current_time) | [.names.bravo_short, .names.alpha_short] | join(\" vs \")") 
end

function _current_gachi_rule --argument-names path_schedule
  set -l current_time (date "+%s")
  echo (command cat $path_schedule | jq -r ".gachi[] | select(.start_time < $current_time) | select(.end_time > $current_time) | .rule.key")
end

function _current_league_rule --argument-names path_schedule
  set -l current_time (date "+%s")
  echo (command cat $path_schedule | jq -r ".league[] | select(.start_time < $current_time) | select(.end_time > $current_time) | .rule.key")
end

function _translate --argument-names key
  # set language
  set -l lang 'JP'
  if set -gq theme_ika_lang; and test -n "$theme_ika_lang"
    set lang $theme_ika_lang
  end

  set -l rule_key_list "coop" "fes" "splat_zones" "rainmaker" "tower_control"
  set -l rule_name_list_jp "サーモンラン" "フェス" "ガチエリア" "ガチホコ" "ガチヤグラ"
  set -l rule_name_list_jp_short "鮭" "祭" "域" "鯱" "櫓"
  set -l rule_name_list_en "Salmon Run" "Festival" "Splat Zones" "Rainmaker" "Tower Control"
  set -l rule_name_list_en_short "Salmon" "Fes" "Zone" "Flag" "Tower"
  #set -l rule_name_list_emoji "🌕🗑️" "💃🏻" "" "" ""

  set -l rule_name_list
  switch $lang
    case "JP"
      set rule_name_list $rule_name_list_jp
    case "EN"
      set rule_name_list $rule_name_list_en
    case "*"
      set rule_name_list $rule_name_list_jp
  end

  set -l index (contains -i $key $rule_key_list)
  if test $status -eq 0
    echo $rule_name_list[$index]
  end
  return $status
end
