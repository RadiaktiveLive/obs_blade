import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/shared/general/base/adaptive_dialog/adaptive_dialog.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import '../../../../models/connection.dart';
import '../../../../models/hidden_scene.dart';
import '../../../../models/hidden_scene_item.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../shared/general/keyboard_number_header.dart';
import '../../../../shared/general/base/adaptive_text_field.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../utils/modal_handler.dart';
import '../../../../utils/validation_helper.dart';

class EditConnectionDialog extends StatefulWidget {
  final Connection connection;

  const EditConnectionDialog({Key? key, required this.connection})
      : super(key: key);

  @override
  _EditConnectionDialogState createState() => _EditConnectionDialogState();
}

class _EditConnectionDialogState extends State<EditConnectionDialog> {
  late CustomValidationTextEditingController _name;
  late CustomValidationTextEditingController _pw;
  late CustomValidationTextEditingController _host;
  late CustomValidationTextEditingController _port;

  late bool _isDomain;

  final FocusNode _portFocusNode = FocusNode();

  bool _obscurePW = true;

  @override
  void initState() {
    super.initState();
    _name = CustomValidationTextEditingController(
      text: this.widget.connection.name,
      check: _nameValidator,
    );
    _host = CustomValidationTextEditingController(
      text: this.widget.connection.host,
      check: this.widget.connection.isDomain == null ||
              !this.widget.connection.isDomain!
          ? ValidationHelper.ipValidator
          : (_) => null,
    );
    _port = CustomValidationTextEditingController(
      text: this.widget.connection.port?.toString() ?? '',
      check: (text) => (text?.isNotEmpty ?? false)
          ? ValidationHelper.portValidator(text)
          : null,
    );

    _pw =
        CustomValidationTextEditingController(text: this.widget.connection.pw);

    _isDomain = this.widget.connection.isDomain ?? false;
  }

  String? _nameValidator(String? name) => (name?.trim().isEmpty ?? true)
      ? 'Please provide a name!'
      : name?.trim() != this.widget.connection.name &&
              Hive.box<Connection>(HiveKeys.SavedConnections.name)
                  .values
                  .any((connection) => connection.name == name)
          ? 'Name already in use!'
          : null;

  @override
  Widget build(BuildContext context) {
    return BaseAdaptiveDialog(
      titleWidget: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Edit Connection'),
          CupertinoButton(
            padding: const EdgeInsets.only(right: 4.0),
            minSize: 0,
            child: const Text(
              'Delete',
              style: TextStyle(color: CupertinoColors.destructiveRed),
            ),
            onPressed: () {
              ModalHandler.showBaseDialog(
                context: context,
                dialogWidget: ConfirmationDialog(
                  title: 'Delete Connection',
                  body:
                      'Are you sure you want to delete this connection? This action can\'t be undone!',
                  isYesDestructive: true,
                  onOk: (_) {
                    Navigator.of(context).pop();
                    this.widget.connection.delete();
                  },
                ),
              );
            },
          ),
        ],
      ),
      bodyWidget: Column(
        children: [
          if (StylingHelper.isApple(context)) const SizedBox(height: 12.0),
          const Text(
            'Change the following information to change your saved connection',
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 4.0),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: BaseAdaptiveTextField(
              controller: _name,
              errorPaddingAlways: true,
              placeholder: 'Name',
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 2,
                child: BaseAdaptiveTextField(
                  controller: _host,
                  placeholder: 'Host',
                  errorPaddingAlways: true,
                  style: const TextStyle(
                    fontFeatures: [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                  bottomWidget: SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<bool>(
                      groupValue: _isDomain,
                      children: const {
                        false: Text('IP'),
                        true: Text('Domain'),
                      },
                      onValueChanged: (domainMode) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() {
                          _isDomain = domainMode ?? false;
                          _host = CustomValidationTextEditingController(
                            text: '',
                            check: !_isDomain
                                ? ValidationHelper.ipValidator
                                : (_) => null,
                          );
                        });
                      },
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: KeyboardNumberHeader(
                    focusNode: _portFocusNode,
                    child: BaseAdaptiveTextField(
                      controller: _port,
                      focusNode: _portFocusNode,
                      errorPaddingAlways: true,
                      style: const TextStyle(
                        fontFeatures: [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                      placeholder: 'Port',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ),
              ),
            ],
          ),
          BaseAdaptiveTextField(
            controller: _pw,
            placeholder: 'Password',
            autocorrect: false,
            obscureText: _obscurePW,
            errorPaddingAlways: true,
            suffixIcon: StylingHelper.isApple(context)
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[
                          Theme.of(context).brightness == Brightness.light
                              ? 300
                              : 900],
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(5.0),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _obscurePW = !_obscurePW),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          _obscurePW ? Icons.visibility_off : Icons.visibility,
                          size: 20.0,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _obscurePW ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscurePW = !_obscurePW),
                  ),
          ),
          // const SizedBox(height: 8.0),
        ],
      ),
      actions: [
        DialogActionConfig(
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
        DialogActionConfig(
          child: const Text('Save'),
          popOnAction: false,
          onPressed: (_) {
            if (_name.isValid && _host.isValid && _port.isValid) {
              String newName = _name.text.trim();
              String newHost = _host.text.trim();

              /// Since [HiddenScene] and [HiddenSceneItem] elements are based on the
              /// connection name and host, once the user updates the connection, we need
              /// to update these elements as well to preserve the status
              if (newName != this.widget.connection.name ||
                  newHost != this.widget.connection.host) {
                Hive.box<HiddenScene>(HiveKeys.HiddenScene.name)
                    .values
                    .forEach((hiddenScene) {
                  if (hiddenScene.connectionName ==
                          this.widget.connection.name ||
                      (hiddenScene.connectionName == null &&
                          hiddenScene.host == this.widget.connection.host)) {
                    hiddenScene.connectionName = newName;
                    hiddenScene.host = newHost;
                    hiddenScene.save();
                  }
                });

                Hive.box<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name)
                    .values
                    .forEach((hiddenSceneItem) {
                  if (hiddenSceneItem.connectionName ==
                          this.widget.connection.name ||
                      (hiddenSceneItem.connectionName == null &&
                          hiddenSceneItem.host ==
                              this.widget.connection.host)) {
                    hiddenSceneItem.connectionName = newName;
                    hiddenSceneItem.host = newHost;
                    hiddenSceneItem.save();
                  }
                });
              }

              this.widget.connection.name = newName;
              this.widget.connection.host = newHost;
              this.widget.connection.port = int.tryParse(_port.text);
              this.widget.connection.pw = _pw.text.trim();
              this.widget.connection.isDomain = _isDomain;
              this.widget.connection.save();
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
