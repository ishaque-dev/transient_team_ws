import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppDefaults {
  static const double radius = 10;
  static const double kDimension5 = 5;
  static const double kDimension8 = 8;
  static const double kDimension10 = 10;
  static const double kDimension15 = 15;
  static const double kDimension20 = 20;
  static const double kDimension25 = 25;
  static const double kDimension30 = 30;
  static const double kDimension40 = 40;
  static const double kDimension50 = 50;

  static EdgeInsets paddingTop10 = EdgeInsets.only(top: kDimension10.h);
  static EdgeInsets paddingTop15 = EdgeInsets.only(top: kDimension15.h);
  static EdgeInsets paddingTop20 = EdgeInsets.only(top: kDimension20.h);
  static EdgeInsets paddingBottom10 = EdgeInsets.only(bottom: kDimension10.h);
  static EdgeInsets paddingBottom15 = EdgeInsets.only(bottom: kDimension15.h);
  static EdgeInsets paddingBottom20 = EdgeInsets.only(bottom: kDimension20.h);
  static EdgeInsets paddingLeft10 = EdgeInsets.only(left: kDimension10.w);
  static EdgeInsets paddingLeft15 = EdgeInsets.only(left: kDimension15.w);
  static EdgeInsets paddingLeft20 = EdgeInsets.only(left: kDimension20.w);
  static EdgeInsets paddingRight10 = EdgeInsets.only(right: kDimension10.w);
  static EdgeInsets paddingRight15 = EdgeInsets.only(right: kDimension15.w);
  static EdgeInsets paddingRight20 = EdgeInsets.only(right: kDimension20.w);
  static EdgeInsets paddingH5 = EdgeInsets.symmetric(horizontal: kDimension5.h);
  static EdgeInsets paddingH10 = EdgeInsets.symmetric(
    horizontal: kDimension10.h,
  );
  static EdgeInsets paddingH15 = EdgeInsets.symmetric(
    horizontal: kDimension15.h,
  );
  static EdgeInsets paddingH20 = EdgeInsets.symmetric(
    horizontal: kDimension20.h,
  );
  static EdgeInsets paddingV5 = EdgeInsets.symmetric(vertical: kDimension5.h);
  static EdgeInsets paddingV10 = EdgeInsets.symmetric(vertical: kDimension10.h);
  static EdgeInsets paddingV15 = EdgeInsets.symmetric(vertical: kDimension15.h);
  static EdgeInsets paddingV20 = EdgeInsets.symmetric(vertical: kDimension20.h);
  static EdgeInsets paddingAll5 = EdgeInsets.symmetric(
    horizontal: kDimension5.w,
    vertical: kDimension5.h,
  );
  static EdgeInsets paddingAll10 = EdgeInsets.symmetric(
    horizontal: kDimension10.w,
    vertical: kDimension10.h,
  );
  static EdgeInsets paddingAll8 = EdgeInsets.symmetric(
    horizontal: kDimension8.w,
    vertical: kDimension8.h,
  );
  static EdgeInsets paddingAll15 = EdgeInsets.symmetric(
    horizontal: kDimension15.w,
    vertical: kDimension15.h,
  );
  static EdgeInsets paddingAll20 = EdgeInsets.symmetric(
    horizontal: kDimension20.w,
    vertical: kDimension20.h,
  );
  static Widget kSizedBoxHeight5 = SizedBox(height: 5.h);
  static Widget kSizedBoxHeight10 = SizedBox(height: 10.h);
  static Widget kSizedBoxHeight15 = SizedBox(height: 15.h);
  static Widget kSizedBoxHeight20 = SizedBox(height: 20.h);
  static Widget kSizedBoxHeight25 = SizedBox(height: 25.h);
  static Widget kSizedBoxHeight30 = SizedBox(height: 30.h);
  static Widget kSizedBoxHeight35 = SizedBox(height: 35.h);
  static Widget kSizedBoxHeight100 = SizedBox(height: 100.h);
  static Widget kSizedBoxHeight50 = SizedBox(height: 50.h);

  static Widget kSizedBoxWidth10 = SizedBox(width: 10.w);
  static Widget kSizedBoxWidth5 = SizedBox(width: 5.w);
  static Widget kSizedBoxWidth15 = SizedBox(width: 15.w);
  static Widget kSizedBoxWidth20 = SizedBox(width: 20.w);

  /// Used For Border Radius
  static BorderRadius kborderRadius10 = BorderRadius.circular(radius);
  static BorderRadius kborderRadius15 = BorderRadius.circular(15.r);
  static BorderRadius kborderRadius20 = BorderRadius.circular(20.r);

  /// Used For Bottom Sheet
  static BorderRadius bottomSheetRadius = BorderRadius.only(
    topLeft: Radius.circular(radius),
    topRight: Radius.circular(radius),
  );

  /// Used For Top Sheet
  static BorderRadius topSheetRadius = BorderRadius.only(
    bottomLeft: Radius.circular(radius),
    bottomRight: Radius.circular(radius),
  );

  /// Default Box Shadow used for containers
  static List<BoxShadow> boxShadow = [
    BoxShadow(
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 2),
      color: Colors.black.withAlpha(10),
    ),
  ];

  static Duration duration = const Duration(milliseconds: 300);
}
