
x = [0., 1., 0., 0., 0., 0.,]
y = [0., 0., 1., 0., 0., 0.,]

za=xcorr(x,y) 
z = [1., 0., 0.,0.,]

println(conv(x,z))
