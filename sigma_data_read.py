import os
import numpy as np
from PIL import Image
import matplotlib.pyplot as plt
import pandas as pd

# data read
dir_data = './drive/MyDrive/EIT_Unet/sigma_datasets'

name_label = 'output_sigma_data.xlsx'
name_input = 'input_sigma_data1.xlsx'

excel_input = os.path.join(dir_data, name_input)
excel_output = os.path.join(dir_data, name_label)

df_in = pd.read_excel(excel_input, header=None)

df_out = pd.read_excel(excel_output, header=None)

data_list = []
ex_data = []
for j in range(df_in.shape[1]):
    input_slice = df_in.iloc[:,j].values.reshape(64, 64)
    output_slice =df_out.iloc[:,j].values.reshape(64, 64)
    data_list.append({'input': input_slice, 'label': output_slice})

##
nframe = 612
nframe_train = 606
nframe_val = 3
nframe_test = 3

dir_save_train = os.path.join(dir_data, 'train')
dir_save_val = os.path.join(dir_data, 'val')
dir_save_test = os.path.join(dir_data, 'test')

if not os.path.exists(dir_save_train):
    os.makedirs(dir_save_train)

if not os.path.exists(dir_save_val):
    os.makedirs(dir_save_val)

if not os.path.exists(dir_save_test):
    os.makedirs(dir_save_test)

##
id_frame = np.arange(nframe)
np.random.shuffle(id_frame)

offset_nframe = 0

# save train
for i in range(nframe_train):
    index = id_frame[i + offset_nframe]
    dic_index = data_list[index]

    label_ = dic_index['label']
    input_ = dic_index['input']

    np.save(os.path.join(dir_save_train, 'label_%03d.npy' % i), label_)
    np.save(os.path.join(dir_save_train, 'input_%03d.npy' % i), input_)

## save val
offset_nframe += nframe_train

for i in range(nframe_val):
    index = id_frame[i + offset_nframe]
    dic_index = data_list[index]

    label_ = dic_index['label']
    input_ = dic_index['input']

    np.save(os.path.join(dir_save_val, 'label_%03d.npy' % i), label_)
    np.save(os.path.join(dir_save_val, 'input_%03d.npy' % i), input_)

## save test
offset_nframe += nframe_val

for i in range(nframe_test):
    index = id_frame[i + offset_nframe]
    dic_index = data_list[index]

    label_ = dic_index['label']
    input_ = dic_index['input']

    np.save(os.path.join(dir_save_test, 'label_%03d.npy' % i), label_)
    np.save(os.path.join(dir_save_test, 'input_%03d.npy' % i), input_)

##
plt.subplot(121)
plt.imshow(label_, cmap='gray')
plt.title('label')

plt.subplot(122)
plt.imshow(input_, cmap='gray')
plt.title('input')

plt.show()