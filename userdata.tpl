#!/bin/bash

/opt/aws/bin/cfn-signal --exit-code $? \
                     --stack  '${stack_name}' \
                     --resource '${resource}'  \
                     --region '${region}'