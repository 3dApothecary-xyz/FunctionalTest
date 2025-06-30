try:
  adxl = printer.lookup_object('adxl345')
#  output(adxl)
  aclient = adxl.start_internal_client()
  printer.lookup_object('toolhead').dwell(.1)
  aclient.finish_measurements()
  values = aclient.get_samples()
  _, x, y, z = values[-1]
  output({
    "x": x,
    "y": y,
    "z": z,
  })
except:
  output("No ADXL345")