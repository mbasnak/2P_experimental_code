"""
code for reading two separate HDF5 files and plotting fly heading vs motor position
Tatsuo Okubo
2021-01-26
"""
import os
import h5py
import matplotlib.pyplot as plt

os.chdir("C:/Users/Tots/Documents/test/20210126_test/ball")
file_name_fictrac = "hdf5_Spontaneous_walking_Closed-loop_20210126_135653_sid_8_tid_1.hdf5"
file_name_arduino = file_name_fictrac.replace(".hdf5", "_arduino.hdf5")
f = h5py.File(file_name_fictrac, 'r')
t1 = f['time']
h = f['heading']

f2 = h5py.File(file_name_arduino, 'r')
t2 = f2['time']
m = f2['motor']

plt.plot(t1, h, 'b.', label='fly heading')
plt.plot(t2, m, 'r.', label='motor position')
plt.legend()
plt.show()