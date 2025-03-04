require 'json'

MAX_MENTSU = 4
MAX_JANTOU = 1

SUUHAI_KIND = 9
ZIHAI_KIND = 7

GC::Profiler.enable

def main
  start_time = Time.now
  suuhai_shanten_list = build_suuhai_shanten_list(start_time)
  zihai_shanten_list = build_zihai_shanten_list(start_time)
  shanten_list = { suuhai: suuhai_shanten_list, zihai: zihai_shanten_list }
  save_file(shanten_list)
end

def build_suuhai_shanten_list(start_time)
  suuhai_tehai_pattern_list = build_tehai_patterns(SUUHAI_KIND)
  suuhai_win_pattern_list = build_suuhai_win_patterns
  cal_shanten(suuhai_tehai_pattern_list, suuhai_win_pattern_list, start_time)
end

def build_zihai_shanten_list(start_time)
  zihai_tehai_pattern_list = build_tehai_patterns(ZIHAI_KIND)
  zihai_win_pattern_list = build_zihai_win_patterns
  cal_shanten(zihai_tehai_pattern_list, zihai_win_pattern_list, start_time)
end

def build_tehai_patterns(kind)
  patterns = (0..4).to_a.repeated_permutation(kind)
  patterns.filter { |pattern| pattern.sum <= 14 }
end

def build_suuhai_win_patterns
  pattern_table = []
  (MAX_MENTSU + 1).times do |number_syuntsu|
    (MAX_MENTSU - number_syuntsu + 1).times do |number_kootsu|
      (MAX_JANTOU + 1).times do |number_jantou|
          syuntsu_table = (0...SUUHAI_KIND - 2).to_a.repeated_permutation(number_syuntsu).to_a #順子を構成要素の開始の数は1〜７のため2を引く
          kootsu_table = (0...SUUHAI_KIND).to_a.repeated_permutation(number_kootsu).to_a
          jantou_table = (0...SUUHAI_KIND).to_a.repeated_permutation(number_jantou).to_a
          
          syuntsu_table.each do |syuntsu_positions|
            kootsu_table.each do |kootsu_positions|
              jantou_table.each do |jantou_positions|
                pattern = [0] * SUUHAI_KIND

                syuntsu_positions.each do |index|
                  pattern[index] += 1
                  pattern[index + 1] += 1
                  pattern[index + 2] += 1
                end
                kootsu_positions.each { |index| pattern[index] += 3 }
                jantou_positions.each { |index| pattern[index] += 2 }
                
                pattern_table << pattern if pattern.all? { |suuhai_count| suuhai_count <= 4 }
              end
            end
          end
        end
      end
    end

  pattern_table.uniq
end

def build_zihai_win_patterns
  pattern_table = []
  (MAX_MENTSU + 1).times do |number_kootsu|
    (MAX_JANTOU + 1).times do |number_jantou|
      kootsu_table = (0...ZIHAI_KIND).to_a.repeated_permutation(number_kootsu).to_a
      jantou_table = (0...ZIHAI_KIND).to_a.repeated_permutation(number_jantou).to_a
      
      kootsu_table.each do |kootsu_positions|
        jantou_table.each do |jantou_positions|
          pattern = [0] * ZIHAI_KIND

          kootsu_positions.each { |index| pattern[index] += 3 }
          jantou_positions.each { |index| pattern[index] += 2 }
          
          pattern_table << pattern if pattern.all? { |zihai_count| zihai_count <= 4 }
        end
      end
    end
  end

  pattern_table.uniq
end

def cal_distance(tehai_pattern_list, win_pattern_list, start_time)
  distance_list = {}

  tehai_pattern_list.each do |tehai|
    win_pattern_list.each_with_index do |win_pattern, index|
      distance = cal_distance(tehai, win_pattern)
      target = win_pattern.sum
      distance_list[tehai] ||= {}
      distance_list[tehai][target] = [distance_list[tehai][target], distance].compact.min
    end
    GC.start #メモリ不足対策
    puts "経過時間：#{(Time.now.hour - start_time.hour)}時間"
  end

  distance_list
end

def cal_distance(hands, targets)
  hands.zip(targets).map { |tile, target| [target - tile, 0].max }.sum
end

def save_file(data)
  File.open('distance_list.json', 'w') { |file| file.write(data.to_json) }
end

main
