function fish_right_prompt
  set -l path_timestamp '/tmp/ika_timestamp.txt'
  set -l path_schedule '/tmp/ika_schedule.json'
  set -l path_fes '/tmp/ika_fes.json'

  _needs_update $path_timestamp $path_schedule $path_fes
  and _update_json_async $path_timestamp $path_schedule $path_fes
  and return 0

  set -l rule_key (_current_rule $path_schedule $path_fes)
  set -l rule_name (_translate $rule_key $theme_ika_lang)
  if test $status -eq 1
    return 0
  end

  set_color $fish_color_autosuggestion ^/dev/null; or set_color 555
  echo $rule_name
  set_color normal
end

function _needs_update --argument-names path_timestamp path_schedule path_fes
  test ! -e $path_timestamp    # timestamp file is not existed
  or test ! -e $path_schedule  # schedule.json is not existed
  or test ! -s $path_schedule  # schedule.json is empty (caused by network error)
  or test ! -e $path_fes       # fes.json is not existed
  or test ! -s $path_fes       # fes.json is empty (caused by network error)
  or test (math (date "+%s") - (cat $path_timestamp)) -ge (math 60 \* 60 \* 12) # cache 12h
end

function _update_json_async --argument-names path_timestamp path_schedule path_fes
  set -l api_endpoint_schedule 'https://splatoon2.ink/data/schedules.json'
  set -l api_endpoint_fes 'https://splatoon2.ink/data/festivals-na.json'
  fish -c "curl -s $api_endpoint_schedule > $path_schedule" &
  fish -c "curl -s $api_endpoint_fes > $path_fes" &
  command date "+%s" > $path_timestamp
end

function _current_rule --argument-names path_schedule path_fes
  if test (command cat $path_fes | jq -r ".festivals | length") -ne 0
    echo 'fes'
  else 
    set -l current_time (date "+%s")
    echo (command cat $path_schedule | jq -r ".gachi[] | select(.start_time < $current_time) | select(.end_time > $current_time) | .rule.key")
  end
end

function _translate --argument-names rule_key lang
  set -q argv[2]; or set lang 'JP'

  set -l rule_name_list_jp "フェス" "ガチエリア" "ガチホコ" "ガチヤグラ"
  set -l rule_name_list_en "Festival" "Splat Zones" "Rainmaker" "Tower Control"
  set -l rule_name_list
  switch $lang
    case "JP"
      set rule_name_list $rule_name_list_jp
    case "EN"
      set rule_name_list $rule_name_list_en
    case "*"
      set rule_name_list $rule_name_list_jp
  end

  switch $rule_key
    case 'fes'
      echo $rule_name_list[1]
      return 0
    case 'splat_zones'
      echo $rule_name_list[2]
      return 0
    case 'rainmaker'
      echo $rule_name_list[3]
      return 0
    case 'tower_control'
      echo $rule_name_list[4]
      return 0
    case '*'
      return 1
  end
end
