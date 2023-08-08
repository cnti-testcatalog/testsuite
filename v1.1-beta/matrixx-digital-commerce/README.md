# MATRIXX Digital Commerce

You will need the images loaded on your system. This test uses versions 5270 ,5261 and 5241 in some cases for rollback.
The main version being tested is 5270.


## Set Up

Set up the testsuite like normal

```
cnf-testsuite setup
```

Then setup the config

```
cnf-testsuite cnf_setup cnf-config=./cnf-testsuite.yml
```

## Running the test

Once every thing is loaded (should take around 6-7mins for all deployments), you can now run the cert test

```
cnf-testsuite cert wait_count=100
```

Please note the wait_count, this is used for increase_decrease_capacity.

## Results

Once its complete, it should produce a results file and output a summary of the results

```
#DCP
total_passed: 31 of 41
essential_passed: 12 of 14

#SBA Events
total_passed: 33 of 41
essential_passed: 12 of 14

#TMF Party Management   
total_passed: 28 of 39
essential_passed: 12 of 14

#TMF Service Activation Management
total_passed: 28 of 39
essential_passed: 12 of 14

#TMF Usage Consumption Management
total_passed: 28 of 39
essential_passed: 12 of 14

#CHF Standalone
total_passed: 37 of 43
essential_passed: 13 of 14
```
