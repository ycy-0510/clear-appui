# Flutter 3.47.8 golden migration

The fork moved from Flutter 3.41.9 to the locally installed 3.47.8 for stable
Widget Preview support. The full behavioral suite passes. CI-style image
comparison identified the following 28 pre-existing references above the
unchanged 0.5% tolerance. Representative button master/test images and text-field
difference images were visually inspected: changes were small test-caption
width and edge-raster differences. Image dimensions are unchanged.

Only failing references were updated from the comparator's actual output;
the tolerance and widget assertions were retained. These are local CI-flavor
references; the hosted Linux workflow remains the cross-host verification.
The new AppUI light/dark references are separate additions.

| Reference | Changed pixels |
| --- | --- |
| test/components/number_field/goldens/ci/number_field.png | 0.95% |
| test/components/number_field/goldens/ci/number_field_dark.png | 0.78% |
| test/components/card/goldens/ci/card_dark.png | 0.59% |
| test/components/alert/goldens/ci/alert.png | 1.11% |
| test/components/alert/goldens/ci/alert_dark.png | 1.14% |
| test/components/otp_field/goldens/ci/otp_field.png | 0.80% |
| test/components/otp_field/goldens/ci/otp_field_dark.png | 0.78% |
| test/components/chip/goldens/ci/chip.png | 0.68% |
| test/components/chip/goldens/ci/chip_dark.png | 0.60% |
| test/components/checkbox/goldens/ci/checkbox.png | 0.71% |
| test/components/checkbox/goldens/ci/checkbox_dark.png | 0.70% |
| test/components/spinner/goldens/ci/spinner.png | 1.21% |
| test/components/spinner/goldens/ci/spinner_dark.png | 1.21% |
| test/components/combobox/goldens/ci/combobox.png | 0.63% |
| test/components/combobox/goldens/ci/combobox_dark.png | 0.52% |
| test/components/toggle/goldens/ci/toggle.png | 0.75% |
| test/components/toggle/goldens/ci/toggle_dark.png | 0.53% |
| test/components/time_picker/goldens/ci/time_picker.png | 0.61% |
| test/components/text_field/goldens/ci/text_field.png | 0.58% |
| test/components/button/goldens/ci/button.png | 1.01% |
| test/components/button/goldens/ci/button_dark.png | 1.00% |
| test/components/button/goldens/ci/button_states.png | 1.08% |
| test/components/button/goldens/ci/button_states_dark.png | 1.04% |
| test/components/switch/goldens/ci/switch.png | 0.54% |
| test/components/select/goldens/ci/select.png | 0.67% |
| test/components/select/goldens/ci/select_dark.png | 0.57% |
| test/components/toggle_group/goldens/ci/toggle_group.png | 0.68% |
| test/components/toggle_group/goldens/ci/toggle_group_dark.png | 0.60% |

## Component QA changes after the SDK migration

The 2026-10-29 component audit intentionally changes geometry for six families:
Tabs (44px targets), NumberField (48px steppers), Radio and Checkbox (48px plain
rows), removable Chip (48px removal target), and Combobox (48px trailing icon
targets). Their light/dark CI references, 12 images, were inspected and updated
with only those six test files selected. These changes are not SDK raster drift.

The first comparison also caught misplaced Progress/Meter value labels after a
flexibility change. Their header now uses an OverflowBar: short content keeps
the label and value at opposite edges; long content moves the value to another
line aligned at the trailing edge. This supports intrinsic layout as well as
narrow large-text layouts. Four further references record the text bounds of
this header change. Their real-font catalog images are checked separately.
The comparator remains at 0.5%.
