Flutter package for integrating with Kyte API.

[![Dart](https://github.com/keyqcloud/kyte_dart/actions/workflows/dart.yml/badge.svg)](https://github.com/keyqcloud/kyte_dart/actions/workflows/dart.yml)

## Features

- handles API signature generation
- session management
- template data models to get started
- easy integration with Kyte Shipyard

## Getting started

The first step is the creaet a `.env` file in the root of your project containing your API and application endpoint information. Below is an example `.env` file:
```
kyte_endpoint=https://api.endpoint.example.com
kyte_identifier=MY_IDENTIFIER_GOES_HERE
kyte_account=MY_ACCOUNT_NUM_GOES_HERE
kyte_publickey=MY_PUBLIC_KEY_GOES_HERE
kyte_secretkey=MY_PRIVATE_KEY_GOES_HERE
kyte_appid=MY_APPLICATION_ID_GOES_HERE
```

## Usage

To get started, you will need to import the kyte_dart package.

```dart
import 'package:kyte_dart/kyte_dart.dart';
import 'package:kyte_dart/api.dart';
import 'package:kyte_dart/http_exception.dart';
```

Once you have a `.env` with your API endpoint information, and imported the necessary packages, you can start making calls to your Kyte API endpoint. To initialize Kyte, simply call

```
var kyte = Kyte();
```

### GET
To make a get request, you will need to define your model and response classes. These files can be automatically generated and downloaded from Kyte Shipyard.

```dart
var kyte = Kyte();
try {
    var response = await kyte.request(
        MyModelResponse.fromJson, KyteRequestType.get, 'MyModel') as MyModelResponse;
    var List<MyModel> myData = [];
    for (var data in response.data!) {
        myData.add(data);
    }
    setState(() {
        _listOfData = myData;
    });
} on HttpException catch (e) {
    var responseCode = e.responseCode ?? 0;
    // do something to handle exception
} catch (e) {
    // do something to handle all other exceptions
}
```

To specify a field-value, for example maybe you only want entries where an attribute named `color` is `orange`.

```dart
var kyte = Kyte();
try {
    var response = await kyte.request(
        MyModelResponse.fromJson, KyteRequestType.get, 'MyModel', field: 'color', value: 'yellow') as MyModelResponse;
    var List<MyModel> myData = [];
    for (var data in response.data!) {
        myData.add(data);
    }
    _listOfData = myData;
} on HttpException catch (e) {
    var responseCode = e.responseCode ?? 0;
    // do something to handle exception
} catch (e) {
    // do something to handle all other exceptions
}
```

### POST
To make a post request, create a JSON formatted body and make a call to your api passing your data in the body.

```dart
var kyte = Kyte();
String body = '{"color": "$myNewColor"}';
try {
    var response = await kyte.request(
        MyModelResponse.fromJson, KyteRequestType.get, 'MyModel',
        body: body) as MyModelResponse;
    if (response.data == null) {
        // handle null data - maybe intentional in controller design or error
    } else {
        // handle non-null data
    }
} on HttpException catch (e) {
    var responseCode = e.responseCode ?? 0;
    // do something to handle exception
} catch (e) {
    // do something to handle all other exceptions
}
```

### PUT
A put request is simliar to a POST request, except you will need to specify a field-value to indicate which entry you are updating. Usually an id for that entry.

```dart
var kyte = Kyte();
String body = '{"color": "$myUpdateColor"}';
try {
    var response = await kyte.request(
        MyModelResponse.fromJson, KyteRequestType.get, 'MyModel',
        field: 'id', value: idx, body: body) as MyModelResponse;
    if (response.data == null) {
        // handle null data - maybe intentional in controller design or error
    } else {
        // handle non-null data
    }
} on HttpException catch (e) {
    var responseCode = e.responseCode ?? 0;
    // do something to handle exception
} catch (e) {
    // do something to handle all other exceptions
}
```

### DELETE
In a get request, you may not require a response from a successful call. The following example shows deleting an entry with a specific id.

```dart
var kyte = Kyte();
try {
    await kyte.request(
        MyModelResponse.fromJson, KyteRequestType.delete, 'MyModel',
        field: 'id', value: idx);
} on HttpException catch (e) {
    var responseCode = e.responseCode ?? 0;
    // do something to handle exception
} catch (e) {
    // do something to handle all other exceptions
}
```
