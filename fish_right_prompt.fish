function fish_right_prompt
  set -l json_path '/tmp/fish_theme_ika.json'

  if not test -e $json_path
    _update_json_async $json_path
    return 0
  end

  set -l rule_key (_current_rule $json_path)
  set -l rule_name (_translate $rule_key $theme_ika_lang)

  # TODO: care about fes
  # TODO: care about downloading state
  if test $status -eq 1
    _update_json_async $json_path
    return 0
  end

  set_color $fish_color_autosuggestion ^/dev/null; or set_color 555
  echo $rule_name
  set_color normal
end

function _update_json_async
  set -l api_endpoint 'https://splatoon2.ink/data/schedules.json'
  fish -c "curl -s $api_endpoint > $argv" &
end

function _current_rule
  set -l current_time (date "+%s")
  echo (command cat $argv | jq -r ".gachi[] | select(.start_time < $current_time) | select(.end_time > $current_time) | .rule.key")
end

function _translate
  set -l rule_key $argv[1]
  set -l lang "JP"
  if set -q argv[2]
    set lang $argv[2] 
  end

  set -l rule_name_list_jp "ガチエリア" "ガチホコ" "ガチヤグラ"
  set -l rule_name_list_en "Splat Zones" "Rainmaker" "Tower Control"
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
    case 'splat_zones'
      echo $rule_name_list[1]
      return 0
    case 'rainmaker'
      echo $rule_name_list[2]
      return 0
    case 'tower_control'
      echo $rule_name_list[3]
      return 0
    case '*'
      return 1
  end
end
