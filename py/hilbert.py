import numpy as np


# press 'Setup Parameters' in the OP to call this function to re-create the parameters.
def onSetupParameters(scriptOp):
	page = scriptOp.appendCustomPage('Conf')
	p = page.appendFloat('Trim', label='How much to trim from start/end')
	p = page.appendFloat('Curveexp', label='Grade')
	return


def onCook(scriptOp):
	# 1) grab your raw audio buffer from input 0
	#    (make sure this CHOP is feeding you a full buffer, not time-sliced)
	buf2d = scriptOp.inputs[0].numpyArray()    # shape = (numChannels, numSamples)
	buf    = buf2d[0]                          # we only need channel 0

	# 2) decide how many samples to process
	#    e.g. use all of them, or just the last N:
	N = buf.shape[0]
	window = buf[-N:]                          # here we're just using the whole thing

	# 3) FFT
	X = np.fft.fft(window)                     # shape = (N,)

	# # 4) build a Hilbert filter of length N
	H = np.zeros(N, dtype=float)
	H[0] = 1.0
	if N % 2 == 0:
		H[N//2] = 1.0
		H[1:N//2] = 2.0
	else:
		H[1:(N+1)//2] = 2.0

	# 5) apply filter & IFFT
	Xh = X * H
	xh = np.fft.ifft(Xh)
	xr = np.fft.ifft(X)

	# 6) split real/imag for plotting:
	trim = int(scriptOp.par.Trim)
	real = xh.real[trim:-trim]
	imag = xh.imag[trim:-trim]

	# 7) pack into 2×N output and send back
	out = np.stack([real, imag])
	scriptOp.clear()

	# Convert to float32
	out = out.astype(np.float32)

	# Push it to Script CHOP
	scriptOp.copyNumpyArray(out, baseName='hilbert_')



	return
