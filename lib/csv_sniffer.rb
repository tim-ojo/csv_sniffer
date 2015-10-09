# This class contains functions to heuristically decipher certain information from a CSV file
class CsvSniffer

    # Reads the first line of the csv and returns true if the line starts and ends with " or '
    def self.is_quote_enclosed?(filepath)
      line = File.open(filepath, &:readline)
      line.chomp!.strip!
      return line.start_with?('"') && line.end_with?('"') || line.start_with?("'") && line.end_with?("'")
    end

    def self.get_quote_char(filepath)
      if is_quote_enclosed?(filepath)
        line = File.open(filepath, &:readline)
        line.chomp!.strip!
        return line[0]
      else
        return nil
      end
    end

    # If the csv is quote enclosed then just get the delimiter after the first cell. Otherwise...
    # Get the first line and count how many of the possible delimiters are present. If there is >1 of one of the
    # delimiters and 0 of the others then, then we pick the max. If there are more than 0 of any of the others then
    # we repeat the counting procedure for the next 50 lines until the condition is satisfied.
    # If the condition is never satisfied then we simply pick the delimiter that occurs the most frequently, defaulting
    # to the comma. Unless that delimeter's count is equal to the tab or pipe delimiter's count. In that case we return \t or |
    def self.detect_delimiter (filepath)

      if is_quote_enclosed?(filepath)
        line = File.open(filepath, &:readline)
        line.chomp!.strip!
        m = /["'].+?["']([,|;\t])/.match(line)
        if (m)
          return m[1]
        end
      end

      lineCount = 0
      File.foreach(filepath) do |line|
        detectedDelim = max_delim_when_others_are_zero(line)
        if detectedDelim != '0' #=> '0' is a sentinel value that indicates no delim found
          return detectedDelim
        end

        lineCount += 1;
        break if lineCount == 50
      end

      # If I got here I'm going to pick the default by counting the delimiters on the first line and returning the max
      line = File.open(filepath, &:readline)
      freqOfPossibleDelims = get_freq_of_possible_delims(line)

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
        return "\t"
      elsif (maxFreq == freqOfPossibleDelims[3])
        return "|"
      else
        return [",", "\t", ";", "|"][maxFreqIndex]
      end
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
