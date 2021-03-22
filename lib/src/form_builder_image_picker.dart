import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:permission_handler/permission_handler.dart';

/// Field for image(s) from user device storage
class FormBuilderImagePicker extends FormBuilderField<PlatformFile?> {
  final double? width;
  final double? height;

  /// Widget to be tapped on by user in order to pick file
  final Widget selectWidget;

  /// Widget to be tapped on by user in order to cancel file
  final Widget cancelWidget;

  /// Allowed file extensions for files to be selected
  final List<String>? allowedExtensions;

  /// If you want to track picking status, for example, because some files may take some time to be
  /// cached (particularly those picked from cloud providers), you may want to set [onFileLoading] handler
  /// that will give you the current status of picking.
  final void Function(FilePickerStatus)? onFileLoading;

  /// Whether to allow file compression
  final bool? allowCompression;

  /// If [withData] is set, picked files will have its byte data immediately available on memory as [Uint8List]
  /// which can be useful if you are picking it for server upload or similar.
  final bool withData;

  /// If [withReadStream] is set, picked files will have its byte data available as a [Stream<List<int>>]
  /// which can be useful for uploading and processing large files.
  final bool withReadStream;

  /// Creates field for image(s) from user device storage
  FormBuilderImagePicker({
    //From Super
    Key? key,
    required String name,
    FormFieldValidator<PlatformFile?>? validator,
    PlatformFile? initialValue,
    InputDecoration decoration = const InputDecoration(border: null),
    ValueChanged<PlatformFile?>? onChanged,
    ValueTransformer<PlatformFile?>? valueTransformer,
    bool enabled = true,
    FormFieldSetter<PlatformFile?>? onSaved,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    VoidCallback? onReset,
    FocusNode? focusNode,
    this.width = null,
    this.height = null,
    this.withData = false,
    this.withReadStream = false,
    this.selectWidget = const Icon(Icons.add_circle),
    this.cancelWidget = const Icon(Icons.delete),
    this.allowedExtensions,
    this.onFileLoading,
    this.allowCompression,
  }) : super(
          key: key,
          initialValue: initialValue,
          name: name,
          validator: validator,
          valueTransformer: valueTransformer,
          onChanged: onChanged,
          autovalidateMode: autovalidateMode,
          onSaved: onSaved,
          enabled: enabled,
          onReset: onReset,
          decoration: decoration,
          focusNode: focusNode,
          builder: (FormFieldState<PlatformFile?> field) {
            final state = field as _FormBuilderFilePickerState;

            return state.defaultFileViewer(state._file, field);
          },
        );

  @override
  _FormBuilderFilePickerState createState() => _FormBuilderFilePickerState();
}

class _FormBuilderFilePickerState
    extends FormBuilderFieldState<FormBuilderImagePicker, PlatformFile?> {
  /// Image File Extensions.
  ///
  /// Note that images may be previewed.
  ///
  /// This list is inspired by [Image](https://api.flutter.dev/flutter/widgets/Image-class.html)
  /// and [instantiateImageCodec](https://api.flutter.dev/flutter/dart-ui/instantiateImageCodec.html):
  /// "The following image formats are supported: JPEG, PNG, GIF,
  /// Animated GIF, WebP, Animated WebP, BMP, and WBMP."
  static const imageFileExts = [
    'gif',
    'jpg',
    'jpeg',
    'png',
    'webp',
    'bmp',
    'dib',
    'wbmp',
  ];

  PlatformFile? _file;

  bool get _remainingItemCount => _file == null;

  @override
  void initState() {
    super.initState();
    _file = widget.initialValue ?? null;
  }

  Future<void> pickFiles(FormFieldState<PlatformFile?> field) async {
    FilePickerResult? resultList;

    try {
      if (await Permission.storage.request().isGranted) {
        resultList = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowedExtensions: widget.allowedExtensions,
          allowCompression: widget.allowCompression,
          onFileLoading: widget.onFileLoading,
          allowMultiple: false,
          withData: widget.withData,
          withReadStream: widget.withReadStream,
        );
      } else {
        throw Exception('Storage Permission not granted');
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    if (resultList != null && resultList.files.isNotEmpty) {
      setState(() => _file = resultList!.files[0]);
      field.didChange(_file);
      widget.onChanged?.call(_file);
    }
  }

  void removeFile(FormFieldState<PlatformFile?> field) {
    setState(() {
      _file = null;
    });
    field.didChange(_file);
    widget.onChanged?.call(_file);
  }

  Widget defaultFileViewer(
      PlatformFile? file, FormFieldState<PlatformFile?> field) {
    final theme = Theme.of(context);

    return Container(
      height: widget.height,
      width: widget.width,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (file != null)
            Positioned.fill(child: Image.file(File(file.path!), width:widget.width, height:widget.height,fit: BoxFit.cover)),
          if (enabled)
            Positioned(
                top: 0,
                right: 0,
                child: _remainingItemCount
                    ? InkWell(
                        child: widget.selectWidget,
                        onTap: () => pickFiles(field),
                      )
                    : InkWell(
                        child: widget.cancelWidget,
                        onTap: () => removeFile(field),
                      )),
        ],
      ),
    );
  }

  IconData getIconData(String fileExtension) {
    return Icons.image;
  }
}
