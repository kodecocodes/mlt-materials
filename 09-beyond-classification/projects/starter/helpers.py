import os, sys, PIL
import numpy as np
import tensorflow as tf

import keras
from keras.preprocessing import image
from keras.applications.mobilenet import preprocess_input

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.patheffects as patheffects


labels = ["apple", "banana", "cake", "candy", "carrot", "cookie",
          "doughnut", "grape", "hot dog", "ice cream", "juice",
          "muffin", "orange", "pineapple", "popcorn", "pretzel",
          "salad", "strawberry", "waffle", "watermelon"]

label2index = {x:i for i, x in enumerate(labels)}


def draw_outline(artist, linewidth):
    artist.set_path_effects([patheffects.Stroke(linewidth=linewidth, foreground="black"),
                             patheffects.Normal()])


def plot_image(img, bounding_boxes, figsize=(10, 10)):
    """Plots one or more bounding boxes on top of the image.
    Each bounding_box is (xmin, xmax, ymin, ymax, class_name).
    The coordinates are expected to be in the range [0, 1].
    """
    def add_rect(ax, width_scale, height_scale, xmin, xmax, ymin, ymax, class_name):
        xmin *= width_scale
        xmax *= width_scale
        ymin *= height_scale
        ymax *= height_scale

        color = "white"
        rect = patches.Rectangle((xmin, ymin), xmax - xmin, ymax - ymin,
                                 linewidth=4, edgecolor=color, facecolor="none")
        patch = ax.add_patch(rect)
        draw_outline(patch, 6)

        text = ax.text(xmin, ymin - 1, class_name, color=color, fontsize="xx-large",
                       verticalalignment="bottom", weight="bold")
        draw_outline(text, 2)

    if type(img) == np.ndarray:
        height_scale, width_scale, _ = img.shape
    else:
        width_scale, height_scale = img.size

    fig, ax = plt.subplots(1, figsize=figsize)
    ax.grid(False)
    ax.imshow(img)

    for box in bounding_boxes:
        add_rect(ax, width_scale, height_scale, *box)

    plt.show()


class BoundingBoxGenerator(keras.utils.Sequence):
    def __init__(self, df, image_dir, image_height, image_width, batch_size, shuffle):
        self.df = df
        self.image_dir = image_dir
        self.image_height = image_height
        self.image_width = image_width
        self.batch_size = batch_size
        self.shuffle = shuffle
        self.on_epoch_end()

    def __len__(self):
        return len(self.df) // self.batch_size

    def __getitem__(self, index):
        # Create NumPy arrays that will hold the images and targets for one batch.
        X = np.empty((self.batch_size, self.image_height, self.image_width, 3))
        y_class = np.empty((self.batch_size), dtype=int)
        y_bbox = np.empty((self.batch_size, 4))

        # Get the indices of the rows that this batch will use.
        batch_rows = self.rows[index * self.batch_size:(index + 1) * self.batch_size]

        for i, row_index in enumerate(batch_rows):
            # Read the row from the dataframe.
            row = self.df.iloc[row_index]

            # Load the image, preprocess it using the standard MobileNet normalization,
            # and put it as a NumPy array into the batch (X).
            image_id = row["image_id"]
            folder = row["folder"]
            image_path = os.path.join(self.image_dir, folder, image_id + ".jpg")
            img = image.load_img(image_path, target_size=(self.image_width, self.image_height))
            img = image.img_to_array(img)
            img = preprocess_input(img)
            X[i, :] = img

            # Convert the class name to a label index, put it into the batch (y_class).
            class_name = row["class_name"]
            class_index = label2index[class_name]
            y_class[i] = class_index

            # Get the bounding box coordinates, put them into the batch (y_bbox).
            # This is a second target. Because we have two losses, we need two targets.
            # Note that we keep the bounding box coordinates as values between 0 and 1,
            # so they are independent of the size of the image.
            x_min = row["x_min"]
            x_max = row["x_max"]
            y_min = row["y_min"]
            y_max = row["y_max"]
            y_bbox[i, :] = np.array([x_min, x_max, y_min, y_max])

        return X, [y_class, y_bbox]

    def on_epoch_end(self):
        self.rows = np.arange(len(self.df))
        if self.shuffle:
            np.random.shuffle(self.rows)


from collections import defaultdict

def combine_histories(histories):
    history = defaultdict(list)
    for h in histories:
        for k in h.history.keys():
            history[k] += h.history[k]
    return history


def plot_loss(history):
    fig = plt.figure(figsize=(10, 6))
    plt.plot(history["loss"])
    plt.plot(history["val_loss"])
    plt.xlabel("Epoch")
    plt.ylabel("Loss")
    plt.legend(["Train", "Validation"], loc="upper right")
    plt.show()


def plot_bbox_loss(history):
    fig = plt.figure(figsize=(10, 6))
    plt.plot(history["bbox_prediction_loss"])
    plt.plot(history["val_bbox_prediction_loss"])
    plt.xlabel("Epoch")
    plt.ylabel("Loss")
    plt.legend(["Train", "Validation"])
    plt.show()


def plot_accuracy(history):
    fig = plt.figure(figsize=(10, 6))
    plt.plot(history["class_prediction_acc"])
    plt.plot(history["val_class_prediction_acc"])
    plt.xlabel("Epoch")
    plt.ylabel("Accuracy")
    plt.legend(["Train", "Validation"])
    plt.show()


def plot_iou(history):
    fig = plt.figure(figsize=(10, 6))
    plt.plot(history["bbox_prediction_mean_iou"])
    plt.plot(history["val_bbox_prediction_mean_iou"])
    plt.xlabel("Epoch")
    plt.ylabel("Mean IOU")
    plt.legend(["Train", "Validation"])
    plt.show()


def iou(coords_true, coords_pred):
    minx = np.maximum(coords_true[0], coords_pred[0])
    maxx = np.minimum(coords_true[1], coords_pred[1])
    miny = np.maximum(coords_true[2], coords_pred[2])
    maxy = np.minimum(coords_true[3], coords_pred[3])
    inters = np.maximum(maxx - minx, 0.) * np.maximum(maxy - miny, 0.)
    area_pred = (coords_pred[1] - coords_pred[0]) * \
                (coords_pred[3] - coords_pred[2])
    area_true = (coords_true[1] - coords_true[0]) * \
                (coords_true[3] - coords_true[2])
    iou = inters / (area_true + area_pred - inters)
    return iou


# Based on code from https://www.davidtvs.com/keras-custom-metrics/
class MeanIOU(object):
    def mean_iou(self, y_true, y_pred):
        # Wraps np_mean_iou method and uses it as a TensorFlow op.
        # Takes numpy arrays as its arguments and returns numpy arrays as
        # its outputs.
        return tf.py_func(self.np_mean_iou, [y_true, y_pred], tf.float32)

    def np_mean_iou(self, y_true, y_pred):
        ious = np.zeros(len(y_true), dtype=np.float32)
        for i in range(len(y_true)):
            ious[i] = iou(y_true[i], y_pred[i])
        return ious.mean()

