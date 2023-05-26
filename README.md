# gnostic proto-gen-openapi naming issue

Relates to issue [#309](https://github.com/google/gnostic/issues/309).

## Steps to Reproduce

### Build Protoc Docker Image including gnostic protoc-gen-openapi
```shell
docker build --tag protoc:local .
```

### Generate OpenAPI Specification
```shell
docker run --rm -it -v $(pwd):/cwd protoc:local --proto_path=/cwd/ --openapi_out=/cwd/ --openapi_opt=naming=proto,fq_schema_naming=false foo.proto
```

Note that the generated yaml file only includes HelloWorld from `bar.proto` which is not referenced anywhere. It should include HelloWorld from `foo.proto` instead. Thus the generated API specification does not reflect the actual API. Method 'Foo' does not return any bar_* fields in its response.

Changing option `fq_schema_naming` to `true` fixes this. It will then only include the correct HelloWorld message from `foo.proto`. I think it should generated a correct API specification in both cases or at least throw an error or warning when a message/schema is ambiguous.