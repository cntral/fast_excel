require_relative 'test_helper'

describe "FastExcel::WorkbookExt close" do

  # The extra field of the first entry's local file header: 0x0001 is the ZIP64 extended information field.
  def first_entry_extra_field_id(file_path)
    header = File.binread(file_path, 30)
    name_length, extra_length = header.unpack("@26vv")
    return nil if extra_length == 0

    File.binread(file_path, 2, 30 + name_length).unpack1("v")
  end

  # Inline strings (constant_memory) at Excel's 32,767 character limit, so one sheet's XML passes 4 GiB in about 131,000 rows.
  def write_past_4_gib(worksheet)
    text = "x" * 32_767
    (2**32 / text.size + 10).times { |row_number| worksheet.write_string(row_number, 0, text, nil) }
  end

  it "should return :no_error when the file is written" do
    workbook = FastExcel.open(constant_memory: true)
    workbook.add_worksheet.write_value(0, 0, "aaa")

    assert_equal(:no_error, workbook.close)
    assert_equal([["aaa"]], parse_xlsx_as_matrix(workbook.filename))
  end

  it "should raise libxlsxwriter's error when the file can not be written" do
    filename = "#{Dir.mktmpdir}/missing_folder/fast_excel.xlsx"
    workbook = FastExcel.open(filename, constant_memory: true)
    workbook.add_worksheet.write_value(0, 0, "aaa")

    error = assert_raises do
      workbook.close
    end

    assert_equal(RuntimeError, error.class)
    assert_equal("Could not write '#{filename}': (2 - error_creating_xlsx_file) Error creating output xlsx file. Usually a permissions error.", error.message)
    refute(workbook.is_open)
  end

  it "should not write ZIP64 records by default" do
    workbook = FastExcel.open(constant_memory: true)
    workbook.add_worksheet.write_value(0, 0, "aaa")
    workbook.close

    assert_nil(first_entry_extra_field_id(workbook.filename))
    assert_equal([["aaa"]], parse_xlsx_as_matrix(workbook.filename))
  end

  it "should write ZIP64 records when use_zip64 is true" do
    workbook = FastExcel.open(constant_memory: true, use_zip64: true)
    workbook.add_worksheet.write_value(0, 0, "aaa")
    workbook.close

    assert_equal(0x0001, first_entry_extra_field_id(workbook.filename))
    assert_equal([["aaa"]], parse_xlsx_as_matrix(workbook.filename))
  end

  # About a minute each and 4 GiB of temporary disk, so they run only when asked: FAST_EXCEL_4GB_TESTS=1 rake test
  it "should raise when a sheet passes 4 GiB without use_zip64" do
    skip "set FAST_EXCEL_4GB_TESTS=1 to write a 4 GiB sheet" unless ENV['FAST_EXCEL_4GB_TESTS']

    workbook = FastExcel.open(constant_memory: true)
    write_past_4_gib(workbook.add_worksheet)

    error = assert_raises do
      workbook.close
    end

    assert_equal("Could not write '#{workbook.filename}': (7 - error_zip_bad_zip_file) Zip error ZIP_BADZIPFILE (use_zip64 option may be required).", error.message)
  ensure
    workbook.remove_tmp_folder if workbook
  end

  it "should write the whole file when a sheet passes 4 GiB with use_zip64" do
    skip "set FAST_EXCEL_4GB_TESTS=1 to write a 4 GiB sheet" unless ENV['FAST_EXCEL_4GB_TESTS']
    require 'zip'

    workbook = FastExcel.open(constant_memory: true, use_zip64: true)
    write_past_4_gib(workbook.add_worksheet)

    assert_equal(:no_error, workbook.close)

    Zip::File.open(workbook.filename) do |zip|
      assert_includes(zip.entries.map(&:name), "xl/workbook.xml")
      assert_operator(zip.find_entry("xl/worksheets/sheet1.xml").size, :>, 2**32)
    end
  ensure
    workbook.remove_tmp_folder if workbook
  end

end
