function fish_right_prompt
  set -l json_path '/tmp/fish_theme_ika.json'

  if not test -e $json_path
    _update_json_async $json_path
    return 0
  end

  set -l rule (_current_rule $json_path)
  set -l rule_jp (_translate $rule)

  # TODO: care about downloading state
  if test $status -eq 1
    _update_json_async $json_path
    return 0
  end

  set_color $fish_color_autosuggestion ^/dev/null; or set_color 555
  echo $rule_jp
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
  switch $argv
    case 'splat_zones'
      echo "ガチエリア"
      return 0
    case 'rainmaker'
      echo "ガチホコ"
      return 0
    case 'tower_control'
      echo "ガチヤグラ"
      return 0
    case '*'
      return 1
  end
end
