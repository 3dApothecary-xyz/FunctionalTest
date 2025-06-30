# updated read_tmc_field.py (printer.cfg's folder)
field = kwargs['field']
stepper = kwargs['stepper']

tmc = printer.lookup_object(f'tmc2209 {stepper}')

register = tmc.fields.field_to_register[field] # Find register for given field

reg_val = tmc.mcu_tmc.get_register(register)
if reg_val == 0: # Queried register
  value = tmc.fields.get_field(field, reg_name=register)
else: # Write-only register
  value = tmc.fields.get_field(field, reg_value=reg_val, reg_name=register)
output(value)