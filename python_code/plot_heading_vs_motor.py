"""
code for reading the HDF5 file and plotting heading vs motor position
Tatsuo Okubo
2021-01-26
"""
import os
import h5py
import matplotlib.pyplot as plt

os.chdir("C:/Users/Tots/Documents/test/20210125_test/ball")
file_name = "hdf5_Spontaneous_walking_Closed-loop_20210126_115119_sid_68_tid_1000001.hdf5"
f = h5py.File(file_name, 'r')
t = f['time']
h = f['heading']
m = f['motor']

plt.plot(t, h, 'b.', label='fly heading')
plt.plot(t, m, 'r.', label='motor position')
plt.legend()
plt.show()