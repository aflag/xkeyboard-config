#
# $Id$
#
# Commont parsing classes for symbols/inet
# The parsing is simplified, based on regex - it is NOT a real parser for very
# complex XKB format
#

class Symbols < Hash

  #
  # Constructor
  #
  def initialize
    @includedSyms = Array.new
  end

  # Write-only property, parent list of symbols definitions
  def symbols_list=(symbolsList)
    @symbolsList = symbolsList
  end

  # Whether this set of symbols is hidden or not
  def hidden?
    @hidden
  end

  def hidden=(h)
    @hidden = h
  end

  #
  # Add "dependency" - the symbols referenced using the "include" statement.
  #
  def add_included(other)
    @includedSyms.push(other)
  end

  alias get_original []

  #
  # Get the symbol, trying first own definitions, then walking through all 
  # dependenies
  #
  def [](symName)
    own = self.get_original(symName)
    if own.nil?
      @includedSyms.find_all do | symsName |
        syms = @symbolsList[symsName]
        his = syms[symName]
        if !his.nil?
          own = his
          break
        end
      end
    end
    own
  end

  #
  # Approximate size - does not take into account overlapping key definitions
  #
  def rough_size()
    @includedSyms.inject(size) do | sum, symsName |
        syms = @symbolsList[symsName]
        syms.size + sum
    end
  end

  #
  # Create a hash including all elements of this hash which are not in the
  # other hash, use symbols + and * for marking the elements which existed in
  # the original hash (+ if not existed)
  #
  def -(other)
    diff = self.class.new
    self.find_all do | key, value | 
      existing = other[key]
      if existing != value
        diff[key] = [ value, existing.nil? ? '+' : '' ]
      end 
    end
    diff
  end


  def to_s
    s = "{\n"
    # First output included syms
    @includedSyms.find_all do | symsName |
       s += "  include \"inet(#{symsName})\"\n"
    end
    # Then - own definitions
    self.find_all do | key, value |
       s += "  key #{key} { [ #{value} ] };\n"
    end
    s + "}";
  end

end

class SymbolsList < Hash

  #
  # Add new xkb_symbols
  #
  def add_symbols (symbolsName, hidden)
    newSyms = Symbols.new
    newSyms.symbols_list = self
    newSyms.hidden = hidden
    self[symbolsName] = newSyms
  end

  def to_s
    s = "// Autogenerated\n\n"
    self.find_all do | symbols, mapping |
      s += "partial alphanumeric_keys\nxkb_symbols \"#{symbols}\" #{mapping};\n\n" 
    end
    s
  end

  def match_symbols(new_symbols,limit)
    matching = Hash.new
    find_all do | symbols, mapping |
      diff = new_symbols - mapping
      if diff.size <= limit
        matching[symbols] = diff
      end
    end
    matching
  end

end

class Parser

  def parse (fileName)
    allSyms = SymbolsList.new;
    currentSyms = nil
    hidden = false
    File.open(fileName) do | file |
      file.each_line do | line |
        line.scan(/xkb_symbols\s+"(\w+)"/) do | symsName |
          currentSyms = allSyms.add_symbols(symsName[0], hidden)
        end
        line.scan(/^\s*key\s*<(\w+)>\s*\{\s*\[\s*(\w+)/) do | keycode, keysym |
          currentSyms[keycode] = keysym
        end
        line.scan(/^partial\s+(hidden\s+)?alphanumeric_keys/) do | h |
          hidden = !h[0].nil?
        end
        line.scan(/^\s*include\s+"inet\((\w+)\)"/) do | otherPart |
          currentSyms.add_included(otherPart[0])
        end
      end
    end
    allSyms
  end

end
