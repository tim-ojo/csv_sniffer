# This class contains functions to heuristically decipher certain information from a CSV file
class CsvSniffer

    # Reads the first line of the csv and returns true if the line starts and ends with " or '
    #
    # Example:
    #   CsvSniffer.is_quote_enclosed?("path/to/file")
    #   =>  true
    #
    # Arguments:
    #   filepath: (String)

    def self.is_quote_enclosed?(filepath)
      begin
        line = File.open(filepath, binmode: 'rt', encoding: 'bom|utf-8:utf-8', &:readline)
        line.chomp!.strip!
        return line.start_with?('"') && line.end_with?('"') || line.start_with?("'") && line.end_with?("'")
      rescue EOFError
        false
      end
    end


    # Gets the quote character in use in the file if one exists. Returns "'", """ or nil
    #
    # Example:
    #   CsvSniffer.get_quote_char("path/to/file")
    #   =>  "
    #
    # Arguments:
    #   filepath: (String)

    def self.get_quote_char(filepath)
      begin
        if is_quote_enclosed?(filepath)
          line = File.open(filepath, binmode: 'rt', encoding: 'bom|utf-8:utf-8', &:readline)
          line.chomp!.strip!
          return line[0]
        else
          return nil
        end
      rescue EOFError
        nil
      end
    end


    # Heuristically detects the delimiter used in the CSV file and returns it
    #
    # Example:
    #   CsvSniffer.detect_delimiter("path/to/file")
    #   =>  "|"
    #
    # Arguments:
    #   filepath: (String)

    def self.detect_delimiter (filepath)
      # If the csv is quote enclosed then just get the delimiter after the first cell. Otherwise...
      # Get the first line and count how many of the possible delimiters are present. If there is >1 of one of the
      # delimiters and 0 of the others then, then we pick the max. If there are more than 0 of any of the others then
      # we repeat the counting procedure for the next 50 lines until the condition is satisfied.
      # If the condition is never satisfied then we simply pick the delimiter that occurs the most frequently, defaulting
      # to the comma. Unless that delimeter's count is equal to the tab or pipe delimiter's count. In that case we return \t or |

      if is_quote_enclosed?(filepath)
        line = File.open(filepath, binmode: 'rt', encoding: 'bom|utf-8:utf-8', &:readline)
        line.chomp!.strip!
        m = /["'].+?["']([,|;\t])/.match(line)
        if (m)
          return m[1]
        end
      end

      lineCount = 0
      File.foreach(filepath, binmode: 'rt', encoding: 'bom|utf-8:utf-8') do |line|
        detectedDelim = max_delim_when_others_are_zero(line)
        if detectedDelim != '0' #=> '0' is a sentinel value that indicates no delim found
          return detectedDelim
        end

        lineCount += 1;
        break if lineCount == 50
      end

      # If I got here I'm going to pick the default by counting the delimiters on the first line and returning the max
      begin
        line = File.open(filepath, binmode: 'rt', encoding: 'bom|utf-8:utf-8', &:readline)
        freqOfPossibleDelims = get_freq_of_possible_delims(line)
      rescue EOFError
        freqOfPossibleDelims = [0,-1,-1,-1]
      end

      maxFreq = 0
      maxFreqIndex = 0
      freqOfPossibleDelims.each_with_index do |delimFreq, i|
        if (delimFreq > maxFreq)
          maxFreq = delimFreq
          maxFreqIndex = i
        end
      end

      # Favor "\t" and "|" over ","
      if (maxFreq == freqOfPossibleDelims[1])
        return '\t'
      elsif (maxFreq == freqOfPossibleDelims[3])
        return "|"
      else
        return [",", '\t', ";", "|"][maxFreqIndex]
      end
    end

    # Heuristically detects whether or not the csv file uses the first line as a header
    #
    # Example:
    #   CsvSniffer.has_header?("path/to/file")
    #   =>  false
    #
    # Arguments:
    #   filepath: (String)

    def self.has_header?(filepath)
      # Creates a dictionary of types of data in each column. If any
      # column is of a single type (say, integers), *except* for the first
      # row, then the first row is presumed to be labels. If the type
      # can't be determined, it is assumed to be a string in which case
      # the length of the string is the determining factor: if all of the
      # rows except for the first are the same length, it's a header.
      # Finally, a 'vote' is taken at the end for each column, adding or
      # subtracting from the likelihood of the first row being a header.
      delim = detect_delimiter(filepath)
      delim = "\t" if delim == "\\t"

      headerRow = nil
      lineCount = 0
      columnTypes = Hash.new
      File.foreach(filepath, binmode: 'rt', encoding: 'bom|utf-8:utf-8') do |line|
        if (!headerRow) # assume the first row is a header
          headerRow = line.split(delim)

          headerRow.each_index do |colIndex|
            columnTypes[colIndex] = nil
          end
          next
        end

        lineCount += 1
        break if lineCount == 50

        row = line.split(delim)
        columnTypes.each_key do |colIndex|
          thisColType = nil
          if (row[colIndex].strip.to_i.to_s == row[colIndex])
            thisColType = Integer
          elsif (row[colIndex].strip.to_f.to_s == row[colIndex])
            thisColType = Float
          else
            # fallback to the length of the string
            thisColType = row[colIndex].strip.length
          end

          if (thisColType != columnTypes[colIndex])
            if (columnTypes[colIndex] == nil)
              # add new column type
              columnTypes[colIndex] = thisColType
            else
              # type is inconsistent, remove from consideration
              columnTypes[colIndex] = nil
            end
          end

        end # end iterate through each row column to determine columnType
      end # end iterate through each row

      # finally, compare results against first row and "vote" on whether its a header
      hasHeader = 0
      columnTypes.each do |colIndex, colVal|
        if colVal.class == NilClass
          # ignore
        elsif (colVal.class != Class) # it's a length
          if (headerRow[colIndex].strip.length != colVal)
            hasHeader += 1
          else
            hasHeader -= 1
          end
        else
          # determine the type of the header and compare it to the type in the Hash
          # if the type is the same then vote down otherwise vote up
          if headerRow[colIndex].strip.to_i.to_s == headerRow[colIndex]
            if colVal == Integer
              hasHeader -= 1
            else
              hasHeader += 1
            end
          elsif headerRow[colIndex].strip.to_f.to_s == headerRow[colIndex]
            if colVal == Float
              hasHeader -= 1
            else
              hasHeader += 1
            end
          end
        end # end type comparison voting branch
      end # end voting loop

      return hasHeader > 0
    end

    def self.max_delim_when_others_are_zero (line)
      freqOfPossibleDelims = get_freq_of_possible_delims(line)

      maxFreq = 0
      maxFreqIndex = 0
      zeroCount = 0
      freqOfPossibleDelims.each_with_index do |delimFreq, i|
        if (delimFreq > maxFreq)
          maxFreq = delimFreq
          maxFreqIndex = i
        end
        zeroCount += 1 if delimFreq == 0
      end

      if zeroCount >= 3
        return [',', '\t', ';', '|'][maxFreqIndex]
      else
        return '0' #=> '0' is a sentinel value that indicates no delim found
      end
    end


    def self.get_freq_of_possible_delims (line)
      freqOfPossibleDelims = Array.new(4) #=> [0 = ','] [1 = '\t'] [2 = ';'] [3 = '|']
      freqOfPossibleDelims[0] = line.count ","
      freqOfPossibleDelims[1] = line.count "\t"
      freqOfPossibleDelims[2] = line.count ";"
      freqOfPossibleDelims[3] = line.count "|"

      return freqOfPossibleDelims
    end


    private_class_method :max_delim_when_others_are_zero
    private_class_method :get_freq_of_possible_delims

end
