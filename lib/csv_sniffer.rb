# This class contains functions to heuristically decipher certain information from a CSV file
class CsvSniffer

    # Reads the first line of the csv and returns true if the line starts and ends with " or '
    def self.is_quote_enclosed?(filepath)
      line = File.open(filepath, &:readline)
      line.chomp!
      return l line.start_with?('"') && line.end_with?('"') || line.start_with?("'") && line.end_with?("'")
    end

end
