adxl = printer.lookup_object('adxl345')
aclient = adxl.start_internal_client()
printer.lookup_object('toolhead').dwell(.1)
aclient.finish_measurements()
values = aclient.get_samples()
if values is None:
  output("No ADXL345")
else:
  _, x, y, z = values[-1]
  output({
    "x": x,
    "y": y,
    "z": z,
  })
