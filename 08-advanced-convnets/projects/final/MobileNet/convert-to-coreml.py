import coremltools
from keras.models import load_model

best_model = load_model("checkpoints/multisnacks-0.7162-0.8419.hdf5")

labels = ["apple", "banana", "cake", "candy", "carrot", "cookie", 
          "doughnut", "grape", "hot dog", "ice cream", "juice", 
          "muffin", "orange", "pineapple", "popcorn", "pretzel",
          "salad", "strawberry", "waffle", "watermelon"]

coreml_model = coremltools.converters.keras.convert(
    best_model,
    input_names="image",
    image_input_names="image",
    output_names="labelProbability",
    predicted_feature_name="label",
    red_bias=-1,
    green_bias=-1,
    blue_bias=-1,
    image_scale=2/255.0,
    class_labels=labels)

coreml_model.author = "Your Name Here"
coreml_model.license = "Public Domain"
coreml_model.short_description = "Image classifier for 20 different types of snacks"

coreml_model.input_description["image"] = "Input image"
coreml_model.output_description["labelProbability"]= "Prediction probabilities"
coreml_model.output_description["label"]= "Class label of top prediction"

print(coreml_model)

coreml_model.save("MultiSnacks.mlmodel")
