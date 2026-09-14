require_relative 'test_helper'

describe "FastExcel::WorksheetExt write_value String detection" do

  before do
    @workbook = FastExcel.open(constant_memory: true)
    @worksheet = @workbook.add_worksheet
  end

  # Writes the value to A1 and reads back what Excel sees: [value, cell type, number format].
  def write_and_read_back(value)
    @worksheet.write_value(0, 0, value)
    @workbook.close

    sheet = parse_xlsx(@workbook.filename).sheet(0)
    [sheet.cell(1, 1), sheet.celltype(1, 1), sheet.excelx_format(1, 1)]
  end

  def assert_written_as_string(value)
    assert_equal([value, :string, "General"], write_and_read_back(value))
  end

  it "should write a whole-cell percentage as a number with a percent format" do
    value, type, format = write_and_read_back("99.5%")

    assert_in_delta(0.995, value, 0.000001)
    assert_equal(:float, type)
    assert_equal("0.0%", format)
  end

  it "should write a whole-cell hh:mm:ss time as a time" do
    value, type, format = write_and_read_back("14:30:00")

    assert_equal(14 * 3600 + 30 * 60, value) # Roo returns times as seconds since midnight.
    assert_equal(:time, type)
    assert_equal("hh:mm:ss", format)
  end

  it "should keep a sentence that ends with a percentage as a string" do
    assert_written_as_string("My percentage is 99.003%")
  end

  it "should keep a multi-line note whose last line is a percentage as a string" do
    assert_written_as_string("Replaced gasket.\n100%")
  end

  it "should keep a multi-line note whose first line is a percentage as a string" do
    assert_written_as_string("100%\nReplaced gasket.")
  end

  it "should keep a multi-line note whose last line is a time as a string" do
    assert_written_as_string("Retorqued flange\n14:30:00")
  end

  it "should keep a percentage with a trailing newline as a string" do
    assert_written_as_string("99%\n")
  end

end
