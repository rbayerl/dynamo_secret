# dynamo_secret
Ruby gem for encrypting secrets with [GnuPG](https://gnupg.org/) and/or
[KMS](https://aws.amazon.com/kms/) and storing them in
[DynamoDB](https://aws.amazon.com/dynamodb/).

## Usage
`dynamo_secret` can be used to store, fetch, update, and delete encrypted
information. It is intended to be used as a remote password store, but could be
used for other things as well. Data is organized by site, and can contain
almost anything.
Usage:
```
dynamo_secret -l|--list
dynamo_secret -i|--init   [-k|--kms]
dynamo_secret -g|--get    [site] [key1,key2,...]
dynamo_secret -a|--add    [site] [key1,key2,...] [val1,val2,...]
dynamo_secret -u|--update [site] [key1,key2,...] [val1,val2,...]
dynamo_secret -d|--delete [site]
```

### List
`dynamo_secret -l` will list all of the sites stored in the DynamoDB table.

### Init
Before storing secrets the table needs to be created. `dynamo_secret -i [-k]`
will create the table. If the optional `-k` flag is supplied a KMS key will
also be created. KMS keys do not qualify for free tier usage and will cost $1
or more per month.

### Get
`dynamo_secret -g|--get [site] [key1,key2,...]` will retreive and decrypt
information stored under the specified site. Specific fields (keys) can also
be specified if not all fields are wanted or required.

### Add
`dynamo_secret -a|--add [site] [key1,key2,...] [val1,val2,...]` stores key
value pairs under `site`. Values may be omitted to keep them out of history
files, or `-` may be used for extra sensitive secrets.

### Update
`dynamo_secret -u|--update` works exactly like `--put`, but it replaces the
specified key value pairs while keeping anything else.

### Delete
`dynamo_secret -d|--delete [site]` completely removes all records under `site`
from the DynamoDB table.
