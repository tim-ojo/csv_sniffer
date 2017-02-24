require 'minitest/autorun'
require 'tempfile'
require 'csv_sniffer'

class CsvSnifferTest < Minitest::Test
  UTF_16_BOM = "\xFF\xFE".force_encoding('utf-16le')

  @@file1 = Tempfile.new('file1', binmode: 'wt+')
  @@file1.puts "Name,Number"
  @@file1.puts "John Doe,555-123-4567"
  @@file1.puts "Jane C. Doe,555-000-1234"
  @@file1.rewind

  @@file2 = Tempfile.new('file2', binmode: 'wt+')
  @@file2.puts "'Name' |'Number'\t"
  @@file2.puts "'John Doe'|'555-123-4567'"
  @@file2.puts "'Jane C. Doe'|'555-000-1234'"
  @@file2.rewind

  @@file3 = Tempfile.new('file3', binmode: 'wt+')
  @@file3.puts "John Doe;555-123-4567;Good\tdude"
  @@file3.puts "Jane C. Doe;555-000-1234   ; Great gal"
  @@file3.puts "John Smith;555-999-1234;Don't know about him"
  @@file3.rewind

  @@file4 = Tempfile.new('file4', binmode: 'wt+')
  @@file4.puts "Doe, John\t555-123-4567"
  @@file4.puts "Jane C. Doe\t555-000-1234\t"
  @@file4.rewind

  @@file5 = Tempfile.new('file5', binmode: 'wt+')
  @@file5.puts '"Doe,,,,,, John"|"555-123-4567"'
  @@file5.puts %{"Jane C. Doe"|"555-000-1234\t"}
  @@file5.rewind

  @@file6 = Tempfile.new('file6', binmode: 'wt+')
  @@file6.puts 'Name|Phone No.|Age'
  @@file6.puts 'Doe, John|555-123-4567|31'
  @@file6.puts 'Doe, Jane C. |555-000-1234|30'
  @@file6.rewind

  @@file7 = Tempfile.new('file7', binmode: 'wt+')
  @@file7.rewind

  @@file8 = Tempfile.new('file8', binmode: 'wt+')
  @@file8.puts '"Name"|"Phone"|"Age"'
  @@file8.puts '"Doe,,,,,, John"|"555-123-4567"|"31"'
  @@file8.puts %{"Jane C. Doe"|"555-000-1234\t"|"30"}
  @@file8.rewind

  @@file9 = Tempfile.new('file9', binmode: 'wt+', encoding: 'utf-16le')
  @@file9.puts UTF_16_BOM + '"Name"|"Phone"|"Age"'.encode('utf-16le')
  @@file9.puts '"Doe,,,,,, John"|"555-123-4567"|"31"'
  @@file9.puts %{"Jane C. Doe"|"555-000-1234\t"|"30"}
  @@file9.rewind

  @@file10 = Tempfile.new('file10', binmode: 'wt+', encoding: 'utf-16le')
  @@file10.puts UTF_16_BOM + 'Name;Phone;Age'.encode('utf-16le')
  @@file10.puts '"Doe John";"555-123-4567";31'
  @@file10.puts %{"Jane C. Doe";"555-000-1234\t";30'}
  @@file10.rewind

  @@file11 = Tempfile.new('file11', binmode: 'wt+')
  @@file11.print "\"Name\",\"Number\"\rJohn ;;;;;;;; Doe,555-123-4567\r"
  @@file11.flush
  @@file11.rewind

  @@file12 = Tempfile.new('file4', binmode: 'wt+')
  @@file12.puts %{"Doe, John"\t"555-123-4567"}
  @@file12.puts %{"Jane C. Doe"\t"555-000-1234\t"}
  @@file12.rewind

  def test_file1
    assert_equal ",", CsvSniffer.detect_delimiter(@@file1.path)
    assert_equal false, CsvSniffer.is_quote_enclosed?(@@file1.path)
    assert_equal nil, CsvSniffer.get_quote_char(@@file1.path)
    assert_equal true, CsvSniffer.has_header?(@@file1.path)
    assert_equal "Name,Number", CsvSniffer.first_line(@@file1.path)
    assert_equal ["Name","Number"], CsvSniffer.first_row(@@file1.path)
  end

  def test_file2
    assert_equal "|", CsvSniffer.detect_delimiter(@@file2.path)
    assert_equal true, CsvSniffer.is_quote_enclosed?(@@file2.path)
    assert_equal "'", CsvSniffer.get_quote_char(@@file2.path)
    assert_equal true, CsvSniffer.has_header?(@@file2.path)
  end

  def test_file3
    assert_equal ";", CsvSniffer.detect_delimiter(@@file3.path)
    assert_equal false, CsvSniffer.is_quote_enclosed?(@@file3.path)
    assert_equal false, CsvSniffer.has_header?(@@file3.path)
  end

  def test_file4
    assert_equal "\t", CsvSniffer.detect_delimiter(@@file4.path)
    assert_equal false, CsvSniffer.is_quote_enclosed?(@@file4.path)
    assert_equal nil, CsvSniffer.get_quote_char(@@file4.path)
    assert_equal false, CsvSniffer.has_header?(@@file4.path)
  end

  def test_file5
    assert_equal "|", CsvSniffer.detect_delimiter(@@file5.path)
    assert_equal true, CsvSniffer.is_quote_enclosed?(@@file5.path)
    assert_equal '"', CsvSniffer.get_quote_char(@@file5.path)
  end

  def test_file6
    assert_equal "|", CsvSniffer.detect_delimiter(@@file6.path)
    assert_equal true, CsvSniffer.has_header?(@@file6.path)
  end

  def test_file7
    assert_equal false, CsvSniffer.has_header?(@@file7.path)
    assert_equal nil, CsvSniffer.get_quote_char(@@file7.path)
    assert_equal ",", CsvSniffer.detect_delimiter(@@file7.path)
  end

  def test_file8
    assert_equal "|", CsvSniffer.detect_delimiter(@@file8.path)
    assert_equal true, CsvSniffer.is_quote_enclosed?(@@file8.path)
    assert_equal '"', CsvSniffer.get_quote_char(@@file8.path)
    assert_equal true, CsvSniffer.has_header?(@@file8.path)
  end

  def test_file9
    assert_equal "|", CsvSniffer.detect_delimiter(@@file9.path)
    assert_equal true, CsvSniffer.is_quote_enclosed?(@@file9.path)
    assert_equal '"', CsvSniffer.get_quote_char(@@file9.path)
    assert_equal true, CsvSniffer.has_header?(@@file9.path)
  end

  def test_file10
    assert_equal ";", CsvSniffer.detect_delimiter(@@file10.path)
    assert_equal false, CsvSniffer.is_quote_enclosed?(@@file10.path)
    assert_equal nil, CsvSniffer.get_quote_char(@@file10.path)
    assert_equal true, CsvSniffer.has_header?(@@file10.path)
  end

  def test_file11
    assert_equal "\r", CsvSniffer.detect_endline(@@file11.path)
    assert_equal ",", CsvSniffer.detect_delimiter(@@file11.path)
    assert_equal true, CsvSniffer.is_quote_enclosed?(@@file11.path)
    assert_equal '"', CsvSniffer.get_quote_char(@@file11.path)
    assert_equal false, CsvSniffer.has_header?(@@file11.path)
  end

  def test_file12
    assert_equal "\t", CsvSniffer.detect_delimiter(@@file12.path)
    assert_equal true, CsvSniffer.is_quote_enclosed?(@@file12.path)
    assert_equal '"', CsvSniffer.get_quote_char(@@file12.path)
    assert_equal false, CsvSniffer.has_header?(@@file12.path)
  end
end
