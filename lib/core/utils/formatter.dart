import 'package:intl/intl.dart';

/// Định dạng giá VNĐ: 14500000 -> "14.500.000đ".
class Formatter {
  Formatter._();

  static final _vnd = NumberFormat.decimalPattern('vi_VN');

  static String price(num value) => '${_vnd.format(value)}đ';

  static String date(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  static String dateTime(DateTime d) => DateFormat('dd/MM HH:mm').format(d);
}
