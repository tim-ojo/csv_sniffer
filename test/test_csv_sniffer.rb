require 'minitest/autorun'
require 'tempfile'
require 'csv_sniffer'

class CsvSnifferTest < Minitest::Test

  @@file1 = Tempfile.new('file1')
  @@file1.puts "Name,Number"
  @@file1.puts "John Doe,555-123-4567"
  @@file1.puts "Jane C. Doe,555-000-1234"
  @@file1.rewind

  @@file2 = Tempfile.new('file2')
  @@file2.puts "'Name' |'Number'\t"
  @@file2.puts "'John Doe'|'555-123-4567'"
  @@file2.puts "'Jane C. Doe'|'555-000-1234'"
  @@file2.rewind

  @@file3 = Tempfile.new('file3')
  @@file3.puts "John Doe;555-123-4567;Good\tdude"
  @@file3.puts "Jane C. Doe;555-000-1234   ; Great gal"
  @@file3.rewind

  @@file4 = Tempfile.new('file4')
  @@file4.puts "Doe, John\t555-123-4567"
  @@file4.puts "Jane C. Doe\t555-000-1234\t"
  @@file4.rewind

  @@file5 = Tempfile.new('file5')
  @@file5.puts '"Doe,,,,,, John"|"555-123-4567"'
  @@file5.puts '"Jane C. Doe"|"555-000-1234\t"'
  @@file5.rewind

  @@file6 = Tempfile.new('file6')
  @@file6.puts 'Doe, John|555-123-4567'
  @@file6.puts 'Doe, Jane C. |555-000-1234'
  @@file6.rewind

  def test_file1
    assert_equal ",", CsvSniffer.detect_delimiter(@@file1.path)
    assert_equal false, CsvSniffer.is_quote_enclosed?(@@file1.path)
    assert_equal nil, CsvSniffer.get_quote_char(@@file1.path)
  end

  def test_file2
    assert_equal "|", CsvSniffer.detect_delimiter(@@file2.path)
    assert_equal true, CsvSniffer.is_quote_enclosed?(@@file2.path)
    assert_equal "'", CsvSniffer.get_quote_char(@@file2.path)
  end

  def test_file3
    assert_equal ";", CsvSniffer.detect_delimiter(@@file3.path)
    assert_equal false, CsvSniffer.is_quote_enclosed?(@@file3.path)
  end

  def test_file4
    assert_equal "\\t", CsvSniffer.detect_delimiter(@@file4.path)
    assert_equal nil, CsvSniffer.get_quote_char(@@file4.path)
  end

  def test_file5
    assert_equal "|", CsvSniffer.detect_delimiter(@@file5.path)
    assert_equal true, CsvSniffer.is_quote_enclosed?(@@file5.path)
    assert_equal '"', CsvSniffer.get_quote_char(@@file5.path)
  end

  def test_file6
    assert_equal "|", CsvSniffer.detect_delimiter(@@file6.path)
  end

end
