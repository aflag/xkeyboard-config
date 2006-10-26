#
# $Id$
# The script finds best matching xkb_symbols in symbols/in
#
# Parameters: $0 - the name of the file with new xkb_symbols
#             $1 - max number of non-matching mappings (0 by default)
#

require "xkbparser.rb"

basedir = "../.."

parser = Parser.new

allSyms = parser.parse("#{basedir}/symbols/inet")

newSyms = parser.parse(ARGV[0])
limit = ARGV[1].to_i

newSyms.find_all do | key, value |

  if value.hidden?
    next
  end

  puts "Existing xkb_symbols matching #{key}: "

  sorted = allSyms.match_symbols(value,limit).sort_by do | symsName, diff |
    sprintf "%03d_%s", diff.size, symsName
  end

  sorted.find_all do | symsName, diff |
    puts "  #{symsName}, up to #{allSyms[symsName].rough_size} keys (difference #{diff.size})-> #{diff}"
  end

end


