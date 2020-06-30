# Converts the MobileNetV2 DeepLabv3+ model to Core ML.
#
# The model is mobilenetv2_coco_voc_trainval, downloaded from:
# http://download.tensorflow.org/models/deeplabv3_mnv2_pascal_trainval_2018_01_29.tar.gz
#
# The main repo page for DeepLabv3+ is:
# https://github.com/tensorflow/models/tree/master/research/deeplab
#
# Tested using Python 3.6.8, TensorFlow 1.13.1, coremltools 3.0, tfcoreml 0.3.0.

import tfcoreml as tf_converter

input_path = 'deeplabv3_mnv2_pascal_trainval/frozen_inference_graph.pb'
output_path = 'DeepLab.mlmodel'

input_tensor = 'ImageTensor:0'
input_name = 'ImageTensor__0'
output_tensor = 'ResizeBilinear_3:0'

tf_converter.convert(tf_model_path=input_path,
                     mlmodel_path=output_path,
                     output_feature_names=[output_tensor],
                     input_name_shape_dict={input_tensor : [1, 513, 513, 3]},
                     image_input_names=input_name)
