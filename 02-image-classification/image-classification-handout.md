```metadata
author: "By Matthijs Hollemans"
number: "2"
title: "Chapter 2: Getting Started with Image Classification"
```

# Chapter 2: Getting Started with Image Classification

Let’s begin your journey into the world of machine learning by creating a binary image classifier.

A **classifier** is a machine learning model that takes an input of some kind, in this case an image, and determines what sort of “thing” that input represents. An image classifier tells you which category, or class, the image belongs to.

**Binary** means that the classifier is able to distinguish between two classes of objects. For example, you can have a classifier that will answer either “cat” or “dog” for a given input image, just in case you have trouble telling the two apart.

![width=75%](images/binary-classifier.png "A binary classifier for cats and dogs")

Being able to tell the difference between only two things may not seem very impressive, but binary classification is used a lot in practice.


$[=s=]
In medical testing, it determines whether a patient has a disease, where the “positive” class means the disease is present and the “negative” class means it’s not. Another common example is filtering email into spam/not spam.

There are plenty of questions that have a definite “yes/no” answer, and the machine learning model to use for such questions is a binary classifier. The cats-vs.-dogs classifier can be framed as answering the question: "Is this a picture of a cat?" If the answer is no, it’s a dog.

Image classification is one of the most fundamental computer vision tasks. Advanced applications of computer vision — such as object detection, style transfer, and image generation — all build on the same ideas from image classification, making this a great place to start.

There are many ways to create an image classifier, but by far the best results come from using deep learning. The success of deep learning in image classification is what started the current hype around AI and ML. We wouldn’t want you to miss out on all this exciting stuff, and so the classifier you’ll be building in this chapter uses deep learning under the hood.

## Is that snack healthy?

In this chapter you’ll learn how to build an image classifier that can tell the difference between healthy and unhealthy snacks.

![width=75%](images/healthy-unhealthy.png "")

To get started, make sure you’ve downloaded the supplementary materials for this chapter and open the **HealthySnacks** starter project in Xcode.

$[=s=]
This is a very basic iPhone app with two buttons, an image view, and a text label at the top:

![width=35%](images/wireframe.png "The design of the app")

The "picture frame" button on the left lets you choose a photo from the library using `UIImagePickerController`. The “camera” button on the right lets you take a picture with the camera (this button is disabled in the simulator).

Once you’ve selected a picture, the app calls `classify(image:)` in **ViewController.swift** to decide whether the image is of a healthy snack or not. Currently this method is empty. In this chapter you’ll be adding code to this method to run the classifier.

At this point, it’s a good idea to take a brief look at **ViewController.swift** to familiarize yourself with the code. It’s pretty standard fare for an iOS app.

In order to do machine learning on the device, you need to have a trained model. For the HealthySnacks app, you’ll need a model that has learned how to tell apart healthy snacks from unhealthy snacks. In this chapter you’ll be using a ready-made model that has already been trained for you, and in the next chapter you’ll learn to how train this model yourself.

$[=s=]
The model is trained to recognize the following snacks:

![width=70%](images/categories-2.png "The categories of snacks")

For example, if you point the camera at an apple and snap a picture, the app should say “healthy”. If you point the camera at a hotdog, it should say "unhealthy."

What the model actually predicts is not just a label (“healthy” or “unhealthy”) but **probability distribution**, where each classification is given a probability value:

![width=70%](images/probability-distribution.png "An example probability distribution")

$[=s=]
If your math and statistics are a little rusty, then don’t let terms such as “probability distribution” scare you. A probability distribution is simply a list of positive numbers that add up to 1.0. In this case it is a list of two numbers because this model has two classes:

```swift
[0.15, 0.85]
```

The above prediction is for an image of a waffle with strawberries on top. The model is 85% sure that the object in this picture is unhealthy. Because the predicted probabilities always need to add up to 100% (or `1.0`), this outcome also means the classifier is 15% sure this snack is healthy — thanks to the strawberries.

You can interpret these probabilities to be the **confidence** that the model has in its predictions. A waffle without strawberries would likely score higher for unhealthy, perhaps as much as 98%, leaving only 2% for class healthy. The more confident the model is about its prediction, the more one of the probabilities goes to 100% and the other goes to 0%. When the difference between them is large, as in this example, it means that the model is sure about its prediction. Ideally, you would have a model that is always confident and never wrong. However, sometimes it’s very hard for the model to draw a solid conclusion about the image. Can *you* tell whether the food in the following image is mostly healthy or unhealthy?

![bordered width=75%](images/ambiguous.png "What is this?")

The less confident the model is, the more both probabilities go towards the middle, or 50%.

$[=s=]
When the probability distribution looks like the following, the model just isn’t very sure, and you cannot really trust the prediction — it could be either class.

![width=70%](images/probability-distribution-unsure.png "An unconfident prediction")

This happens when the image has elements of both classes — salad and greasy stuff — so it’s hard for the model to choose between the two classes. It also happens when the image is not about food at all, and the model does not know what to make of it.

To recap, the input to the image classifier is an image and the output is a probability distribution, a list of numbers between 0 and 1.

Since you’re going to be building a binary classifier, the probability distribution is made up of just two numbers. The easiest way to decide which class is the winner is to choose the one with the highest predicted probability.

> **Note**: To keep things manageable for this book, we only trained the model on twenty types of snacks (ten healthy, ten unhealthy). If you take a picture of something that isn’t in the list of twenty snacks, such as broccoli or pizza, the prediction could be either healthy or unhealthy. The model wasn’t trained to recognize such things and, so, what it predicts is anyone’s guess. That said, the model might still guess right on broccoli (it’s green, which is similar to other healthy snacks) and pizza (it’s greasy and therefore unhealthy).

$[=s=]

## Core ML

For many of the projects in this book, you’ll be using Core ML, Apple’s machine learning framework that was introduced with iOS 11. Core ML makes it really easy to add machine learning models to your app — it’s mostly a matter of dropping a trained model into your app and calling a few API functions. Xcode even automatically writes most of the code for you.

Of course, Core ML is only easy if you already have a trained model. You can find the model for this chapter, **HealthySnacks.mlmodel**, in the downloaded resources.

Core ML models are packaged up in a **.mlmodel** file. This file contains both the structural definition of the model as well as the things it has learned, known as the learned parameters (or the "weights").

With the HealthySnacks project open in Xcode, drag the **HealthySnacks.mlmodel** file into the project to add it to the app (or use File ▸ Add Files).

Select **HealthySnacks.mlmodel** in the Project Navigator and Xcode will show the following:

![bordered width=100%](images/model-summary.png "Looking at the mlmodel file")

This is a summary of the Core ML model file. It shows what of type model it is, the size of the model in megabytes and a description.

The HealthySnacks model type is Neural Network Classifier, which means it is an image classifier that uses deep learning techniques. The terms “deep learning” and “neural network” mean pretty much the same thing. According to the description, this model was made using a tool called Turi Create and it uses SqueezeNet v1.1, a popular deep learning architecture for mobile apps.

The main benefit of SqueezeNet is that it’s small. As you can see in Xcode, the size of this model is “only” 5 MB. That is tiny compared to many other deep learning model architectures, which can take up hundreds of MBs. Such large models are usually not a good choice for use in a mobile app. Not only do they make the app download bigger but larger models are also slower and use more battery power.

The Model Evaluation Parameters section lists the inputs that the model expects and the outputs that it produces. Since this is an image classifier there is only one input, a color image that must be 227 pixels wide and 227 pixels tall. You cannot use images with other dimensions. The reason for this restriction is that the SqueezeNet architecture expects an image of exactly this size. If it’s any smaller or any larger, the math used by SqueezeNet doesn’t work out. This means that any image you pick from the photo library or take with the camera must be resized to 227×227 before you can use it with this Core ML model.

> **Note**: If you’re thinking that 227×227 pixels isn’t very big, then you’re right. A typical 12-megapixel photo is 4032×3024 — that is more than 200 times as many pixels! But there is a trade-off between image size and processing time. These deep learning models need to do *a lot* of calculations: For a single 227×227 image, SqueezeNet performs 390 million calculations. Make the image twice as large and the number of calculations also doubles. At some point, that just gets out of hand and the model will be too slow to be useable!
>
> Making the image smaller will make the model faster, and it can even help the models learn better since scaling down the image helps to remove unnecessary details that would otherwise just confuse the model. But there’s a limit here too: At some point, the image loses too much detail, and the model won’t be able to do a good job anymore. For image classification, 227×227 is a good compromise. Other typical image sizes used with deep learning models are 224×224 and 299×299.

$[=s=]
The HealthySnacks model has two outputs. It puts the probability distribution into a dictionary named `labelProbability` that will look something like this:

```swift
labelProbability = [ "healthy": 0.15, "unhealthy": 0.85 ]
```

For convenience, the second output it provides is the class label of the top prediction: `"healthy"` if the probability of the snack being healthy is greater than 50%, `"unhealthy"` if it’s less than 50%.

The final section of this model summary to look at is Model Class. When you add an .mlmodel file to a project, Xcode does something smart behind the scenes: It creates a Swift class with all the source code needed to use the model in your app. That means you don’t have to write any code to load the .mlmodel — Xcode has already done the heavy lifting for you.

To see the code that Xcode generated, click the little arrow next to the model name:

![bordered width=100%](images/view-model-code-button.png "Click the arrow to view the generated code")

It’s not important, at this point, that you understand exactly what this code does; just notice that the automatically generated Swift file contains a class `HealthySnacks` that has an `MLModel` object property (the main object from the Core ML framework). It also has `prediction()` methods for making the classifications. There also are `HealthySnacksInput` and `HealthySnacksOutput` classes that represent the inputs (an image) and outputs (the probabilities dictionary and the top prediction label) of the model.

At this point, you might reasonably expect that you’re going to use these automatically generated classes to make the predictions. Surprise… you’re not! We’re saving that for the end of the chapter.

There are a few reasons for this, most importantly that the images need to be scaled to 227×227 pixels and placed into a `CVPixelBuffer` object before you can call the `prediction()` method, and we'd rather not deal with that if we can avoid it. So instead, you’re going to be using yet another framework: Vision.

$[=s=]
> **Note**: Core ML models can also have other types of inputs besides images, such as numbers and text. In this first section of the book, you’ll primarily work with images but, in later sections, you’ll also do machine learning on other types of data.

## Vision

Along with Core ML, Apple also introduced the Vision framework in iOS 11. As you can guess from its name, Vision helps with computer vision tasks. For example, it can detect rectangular shapes and text in images, detect faces and even track moving objects.

Most importantly for you, Vision makes it easy to run Core ML models that take images as input. You can even combine this with other Vision tasks into an efficient image-processing pipeline. For example, in an app that detects people’s emotions, you can build a Vision pipeline that first detects a face in the image and then runs a Core ML-based classifier on just that face to see whether the person is smiling or frowning.

It’s highly recommended that you use Vision to drive Core ML if you’re working with images. Recall that the HealthySnacks model needs a 227×227 image as input, but images from the photo library or the camera will be much larger and are typically not square. Vision will automatically resize and crop the image.

In the automatically generated Swift file for the .mlmodel, you may have noticed that the input image (see `HealthySnacksInput`) has to be a `CVPixelBuffer` object, while `UIImagePickerController` gives you a `UIImage` instead. Vision can do this conversion for you, so you don’t have to worry about `CVPixelBuffer` objects.

Finally, Vision also performs a few other tricks, such as rotating the image so that it’s always right-size up, and matching the image’s color to the device’s color space. Without the Vision framework, you'd have to write additional code by hand! Surely, you’ll agree that it’s much more convenient to let Vision handle all these things.

> **Note**: Of course, if you’re using a model that does not take images as input, you can’t use Vision. In that case, you’ll have to use the Core ML API directly.

The way Vision works is that you create a `VNRequest` object, which describes the task you want to perform, and then you use a `VNImageRequestHandler` to execute the request. Since you’ll use Vision to run a Core ML model, the request is a subclass named `VNCoreMLRequest`. Let’s write some code!

$[=s=]

## Creating the VNCoreMLRequest

To add image classification to the app, you’re going to implement `classify(image:)` in **ViewController.swift**. This method is currently empty. Here, you’ll use Vision to run the Core ML model and interpret its results. First, add the required imports to the top of the file:

```swift
import CoreML
import Vision
```

Next, you need to create the `VNCoreMLRequest` object. You typically create this request object once and re-use it for every image that you want to classify. Don’t create a new request object every time you want to classify an image — that’s wasteful.

In **ViewController.swift**, add the following code inside the `ViewController` class below the `@IBOutlet`s:

```swift
lazy var classificationRequest: VNCoreMLRequest = {
  do {
    // 1
    let healthySnacks = HealthySnacks()
    // 2
    let visionModel = try VNCoreMLModel(for: healthySnacks.model)
    // 3
    let request = VNCoreMLRequest(model: visionModel,
                                  completionHandler: {
      [weak self] request, error in
      print("Request is finished!", request.results)
    })
    // 4
    request.imageCropAndScaleOption = .centerCrop
    return request
  } catch {
    fatalError("Failed to create VNCoreMLModel: \(error)")
  }
}()
```

Here’s what this code does:

1. Create an instance of `HealthySnacks`. This is the class from the .mlmodel file’s automatically generated code. You won’t use this class directly, only so you can pass its `MLModel` object to Vision.

2. Create a `VNCoreMLModel` object. This is a wrapper object that connects the `MLModel` instance from the Core ML framework with Vision.

$[=s=]
3. Create the `VNCoreMLRequest` object. This object will perform the actual actions of converting the input image to a `CVPixelBuffer`, scaling it to 227×227, running the Core ML model, interpreting the results, and so on.

   Since Vision requests run asynchronously, you need to supply a completion handler that will receive the results. For now, the completion handler just prints something to the Xcode debug output pane. You will flesh this out later.

4. The `imageCropAndScaleOption` tells Vision how it should resize the photo down to the 227×227 pixels that the model expects.

The code is wrapped up in a `do catch` because loading the `VNCoreMLModel` object can fail if the .mlmodel file is invalid somehow. That should never happen in this example project, and so you handle this kind of error by crashing the app. It is possible for apps to download an .mlmodel file and, if the download fails, the .mlmodel can get corrupted. In that case, you’ll want to handle this error in a more graceful way.

> **Note**: The `classificationRequest` variable is a `lazy` property. In case you’re unfamiliar with lazy properties, this just means that the `VNCoreMLRequest` object is not created until the very first time you use `classificationRequest` in the app.

### Crop and scale options

It has been mentioned a few times now that the model you’re using, which is based on SqueezeNet, requires input images that are 227×227 pixels. Since you’re using Vision, you don’t really need to worry about this — Vision will automatically scale the image to the correct size. However, there is more than one way to resize an image, and you need to choose the correct method for the model, otherwise it might not work as well as you'd hoped.

What the correct method is for your model depends on how it was trained. When a model is trained, it’s shown many different example images to learn from. Those images have all kinds of different dimensions and aspect ratios, and they also need to be resized to 227×227 pixels. There are different ways to do this and not everyone uses the same method when training their models.

For the best results you should set the request’s `imageCropAndScaleOption` property so that it uses the same method that was used during training.

$[=s=]
Vision offers three possible choices:

- `centerCrop`
- `scaleFill`
- `scaleFit`

The `.centerCrop` option first resizes the image so that the smallest side is 227 pixels, and then it crops out the center square:

![width=80%](images/center-crop.png "The centerCrop option")

Note that this removes pixels from the left and right edges of the image (or from the top/bottom if the image is in portrait). If the object of interest happens to be in that part of the image, then this will throw away useful information and the classifier may only see a portion of the object. When using `.centerCrop` it’s essential that the user points the camera so that the object is in the center of the picture.

With `.scaleFill`, the image gets resized to 227×227 without removing anything from the sides, so it keeps all the information from the original image — but if the original wasn’t square then the image gets squashed. Finally, `.scaleFit` keeps the aspect ratio intact but compensates by filling in the rest with black pixels.

![width=55%](images/scale-fill-fit.png "The scaleFill and scaleFit options")

For the Healthy Snacks app, you’ll use `.centerCrop` as that’s also the resizing strategy that was used to train the model. Just make sure that the object you’re pointing the camera at is near the center of the picture for the best results. Feel free to try out the other scaling options to see what kind of difference they make to the predictions, if any.

$[=s=]
## Performing the request

Now that you have the request object, you can implement the `classify(image:)` method. Add the following code to that method:

```swift
func classify(image: UIImage) {
  // 1
  guard let ciImage = CIImage(image: image) else {
    print("Unable to create CIImage")
    return
  }
  // 2
  let orientation = CGImagePropertyOrientation(image.imageOrientation)
  // 3
  DispatchQueue.global(qos: .userInitiated).async {
    // 4
    let handler = VNImageRequestHandler(ciImage: ciImage,
                                        orientation: orientation)
    do {
      try handler.perform([self.classificationRequest])
    } catch {
      print("Failed to perform classification: \(error)")
    }
  }
}
```

The image that you get from `UIImagePickerController` is a `UIImage` object but Vision prefers to work with `CGImage` or `CIImage` objects. Either will work fine, and they’re both easy to obtain from the original `UIImage`. The advantage of using a `CIImage` is that this lets you apply additional Core Image transformations to the image, for more advanced image processing.

Here is what the method does, step-by-step:

1. Converts the `UIImage` to a `CIImage` object.
2. The `UIImage` has an `imageOrientation` property that describes which way is up when the image is to be drawn. For example, if the orientation is "down," then the image should be rotated 180 degrees. You need to tell Vision about the image’s orientation so that it can rotate the image if necessary, since Core ML expects images to be upright.
3. Because it may take Core ML a moment or two to do all the calculations involved in the classification (recall that SqueezeNet does 390 million calculations for a single image), it is best to perform the request on a background queue, so as not to block the main thread.

$[=s=]
4. Create a new `VNImageRequestHandler` for this image and its orientation information, then call `perform()` to actually do execute the request. Note that `perform()` takes an array of `VNRequest` objects, so that you can perform multiple Vision requests on the same image if you want to. Here, you just use the `VNCoreMLRequest` object from the `classificationRequest` property you made earlier.

The above steps are pretty much the same for any Vision Core ML app.

Because you made the `classificationRequest` a `lazy` property, the very first time `classify(image:)` gets called it will load the Core ML model and set up the Vision request. But it only does this once and then re-uses the same request object for every image. On the other hand, you do need to create a new `VNImageRequestHandler` every time, because this handler object is specific to the image you’re trying to classify.

### Image orientation

When you take a photo with the iPhone’s camera, regardless of how you’re holding the phone, the image data is stored as landscape because that’s the native orientation of the camera sensor. iOS keeps track of the true orientation of the image with the `imageOrientation` property. For an image in your photo album, the orientation information is stored in the image file’s EXIF data.

If you’re holding the phone in portrait mode and snap a picture, its `imageOrientation` will be `.right` to indicate the camera has been rotated 90 degrees clockwise — 0 degrees means that the phone was in landscape with the Home button on the right.

An `imageOrientation` of `.up` means that the image already has the correct side up. This is true for pictures taken in landscape but also for portrait pictures from other sources, such as an image you create in Photoshop.

Most image classification models expect to see the input image with the correct side up. Notice that the Core ML model does not take “image orientation” as an input, so it will see only the "raw" pixels in the image buffer without knowing which side is up.

Image classifiers are typically trained to account for images being horizontally flipped so that they can recognize objects facing left as well as facing right, but they’re usually not trained to deal with images that rotated by 90, 180 or 270 degrees.

$[=s=]
If you pass in an image that is not oriented properly, the model may not give accurate predictions because it has not learned to look at images that way.

![width=75%](images/image-orientation.png "This cat is not right-side up")

This is why you need to tell Vision about the image’s orientation so that it can properly rotate the image’s pixels before they get passed to Core ML. Since Vision uses `CGImage` or `CIImage` instead of `UIImage`, you need to convert the `UIImage.Orientation` value to a `CGImagePropertyOrientation` value.

### Trying it out

At this point, you can build and run the app and choose a photo.

It’s possible to run this app in the Simulator but only the photo library button is active. The photo library on the Simulator doesn’t contain pictures of snacks by default, but you can add your own by Googling for images and then dragging those JPEGs or PNGs into the Photos app.

Run the app on a device to use the camera, as the Simulator does not support taking pictures.

Take or choose a picture, and the Xcode debug pane will output something like this:

```none
Request is finished! Optional([<VNClassificationObservation: 0x60c00022b940> B09B3F7D-89CF-405A-ABE3-6F4AF67683BB 0.81705 "healthy" (0.917060), <VNClassificationObservation: 0x60c000223580> BC9198C6-8264-4B3A-AB3A-5AAE84F638A4 0.18295 "unhealthy" (0.082940)])
```

This is the output from the `print` statement in the completion handler of the `VNCoreMLRequest`. It prints out the `request.results` array. As you can see, this array contains two `VNClassificationObservation` objects, one with the probability for the healthy class (91.7%) and the other with the probability for the unhealthy class (8.29%).

Congratulations — you’ve gotten your first taste of Machine Learning on iOS!

$[=s=]
## Where to go from here?

In this sample of _Machine Learning by Tutorials_, the chapter ends here.

However, in the full version of the chapter, you’ll continue where this leaves off and:

* Show these results in the app’s GUI.
* Learn how to handle "unsure" results.
* Learn how this model works under the hood.
* Take a deeper dive into the math of neural networks.
* Work with models that handle more than two classes.
* Learn how to use CoreML without Vision.

And this is only the first chapter in the book! 