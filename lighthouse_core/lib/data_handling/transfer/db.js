import { ok, notFound, serverError, badRequest, created, forbidden, response } from 'wix-http-functions';
import wixData from 'wix-data';
import { getSecret } from 'wix-secrets-backend';
const crypto = require("crypto");
// https://infinitumlabsinc.editorx.io/lighthousecloud/_functions/getById

function options() {
    return {
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Authorization": null
        },
        "body": {
            "status": {
                "code": 200, // CHANGE TO 500
                "msg": "Default response"
            },
            "payload": []
        }
    }
};

class Authorisation {
    generateBody(userId) {
        var timeNow = Math.round(Date.now() / 1000);
        return {
            "headers": {
                "alg": "RS256",
                "typ": "JWT"
            },
            "payload": {
                "iat": timeNow,
                "exp": timeNow + 1200, // valid for 20 minutes
                "sub": userId
            }
        };
    }

    hashBody(body) {
        return crypto.createHash('sha256').update(JSON.stringify(body)).digest('base64');
    }

    encryptBody(hashedBody) {
        return getSecret("jwt_private_key").then((value) => crypto.privateEncrypt(crypto.createPrivateKey(value), Buffer.from(hashedBody, 'base64')).toString('base64'));

    }

    decryptBody(encryptedBody) {
        return getSecret("jwt_private_key").then((value) => crypto.publicDecrypt(crypto.createPrivateKey(value), Buffer.from(encryptedBody, 'base64')).toString('base64'));
    }

    validateJWT(body, signature, action) {
        var res = options();
        return this.decryptBody(signature.replace("Bearer ", '')).then((decryptedBody) => {
            var isEqual = this.hashBody(JSON.parse(body)) == decryptedBody;
            var isValid = JSON.parse(body)['payload']['exp'] > Math.round(Date.now() / 1000);
            if (isEqual) {
                if (isValid) {
                    return action(res);
                } else {
                    res.status = res.body.status.code = 401;
                    res.body.status.msg = "JWT token has expired. Please login again.";
                    return response(res);
                }
            } else if (!isEqual) {
                res.status = res.body.status.code = 401;
                res.body.status.msg = "JWT payload hash does not match decrypted signature: JWT may have been tampered with. Service denied.";
                return response(res);
            } else {
                res.status = res.body.status.code = 500;
                res.body.status.msg = "JWT payload validation failed (null returned)";
                return response(res);
            }
        }).catch((err) => {
            console.log(err);
            res.status = res.body.status.code = 500;
            res.body.status.msg = err;
            return response(res);
        });

    }
}

const auth = new Authorisation();

function buildQuery(dataQuery, queryObject) {
    var filter = dataQuery;
    for (const f of queryObject) {
        switch (f.type) {
            case 'between':
                filter = filter.between(f.prop, f.rangeStart, f.rangeEnd);
                break;
            case 'contains':
                filter = filter.contains(f.prop, f.substring);
                break;
            case 'eq':
                filter = filter.eq(f.prop, f.value);
                break;
            case 'ne':
                filter = filter.ne(f.prop, f.value);
                break;
            case 'gt':
                filter = filter.gt(f.prop, f.value);
                break;
            case 'ge':
                filter = filter.ge(f.prop, f.value);
                break;
            case 'lt':
                filter = filter.lt(f.prop, f.value);
                break;
            case 'le':
                filter = filter.le(f.prop, f.value);
                break;
            case 'hasSome':
                filter = filter.hasSome(f.prop, f.values);
                break;
        }
    }
    return filter;
}

export function get_getJwtToken(request) {
    var res = options();
    res.body.payload.length = 0;
    return wixData.query("Users")
        .contains("emailAddress", request.query.emailAddress)
        // .contains("password", request.query.password) // to detect incorrect password
        .find()
        .then((result) => {
            if (result.items.length == 0) {
                res.status = res.body.status.code = 404;
                res.body.status.msg = "No users with that email address";
                return response(res);
            } else {
                var item = result.items[0];
                if (request.query.password == item['password']) {
                    res.status = res.body.status.code = 200;
                    res.body.status.msg = "OK";
                    var body = auth.generateBody(item['objectId']);
                    return auth.encryptBody(auth.hashBody(body)).then((encryptedBody) => {
                        body.signature = encryptedBody;
                        res.body.payload = [body];
                        return response(res);
                    }).catch((err) => {
                        console.log(err);
                        res.status = res.body.status.code = 500;
                        res.body.status.msg = err;
                        return response(res);
                    });
                } else {
                    res.status = res.body.status.code = 403;
                    res.body.status.msg = "Incorrect password";
                    return response(res);
                }
            }
        }).catch((err) => {
            console.log(err);
            res.status = res.body.status.code = 500;
            res.body.status.msg = err;
            return response(res);
        });
}

export function get_getById(request) {
    return auth.validateJWT(request.query['jwt'], request.headers.authorization, (res) => {
        return wixData.query(request.query.collectionId)
            .eq('objectId', request.query.objectId)
            .find()
            .then((result) => {
                if (result.items.length == 0) {
                    res.status = res.body.status.code = 404;
                    res.body.status.msg = "No items in collection with a matching ID.";
                    return response(res);
                } else {
                    res.status = res.body.status.code = 200;
                    res.body.status.msg = "OK";
                    res.body.payload = result.items;
                    return response(res);
                }
            }).catch((err) => {
                console.log(err);
                res.status = res.body.status.code = 500;
                res.body.status.msg = err;
                return response(res);
            });
    });

}

export function get_bulkGetByFilter(request) {
    return auth.validateJWT(request.query['jwt'], request.headers.authorization, (res) => {
        var queryObject = request.query.queryObject;
        var query = buildQuery(wixData.query(request.query.collectionId), JSON.parse(queryObject));
        return query.find()
            .then((items) => {
                res.body.status.code = 200;
                res.body.status.msg = "OK";
                res.body.payload = items['items'];
                res.status = res.body.status.code;
                return response(res);
            })
            .catch((err) => {
                console.log(err);
                res.body.status.code = 500;
                res.body.status.msg = err;
                res.status = res.body.status.code;
                return response(res);
            });
    });
}

export function post_create(request) {
    return auth.validateJWT(request.query['jwt'], request.headers.authorization, (res) => {
        return request.body.text()
            .then((text) => {
                return wixData.insert(request.query.collectionId, JSON.parse(text));
            })
            .then((_) => {
                res.body.status.code = 201;
                res.body.status.msg = "OK";
                res.status = res.body.status.code;
                return response(res);
            })
            .catch((err) => {
                console.log(err);
                res.body.status.code = 500;
                res.body.status.msg = err;
                res.status = res.body.status.code;
                return response(res);
            });
    });
}

export function post_bulkCreate(request) {
    return auth.validateJWT(request.query['jwt'], request.headers.authorization, (res) => {
        return request.body.text()
            .then((text) => {
                return wixData.bulkInsert(request.query.collectionId, JSON.parse(text));
            })
            .then((_) => {
                res.body.status.code = 201;
                res.body.status.msg = "OK";
                res.status = res.body.status.code;
                return response(res);
            })
            .catch((err) => {
                console.log(err);
                res.body.status.code = 500;
                res.body.status.msg = err;
                res.status = res.body.status.code;
                return response(res);
            });
    });
}

export function use_replaceById(request) {
    // unverified endpoint
    var res = options();
    return request.body.text()
        .then((text) => {
            return wixData.query(request.query.collectionId)
                .eq('objectId', request.query.objectId)
                .find()
                .then((result) => {
                    if (result.items.length == 0) {
                        res.body.status.code = 404;
                        res.body.status.msg = "No items in collection with a matching ID.";
                    } else {
                        res.body.status.code = 200;
                        res.body.status.msg = "OK";
                        var obId = result.items.find(e => e['objectId'] == request.query.objectId)['_id'];
                        var item = JSON.parse(text);
                        item['_id'] = obId;
                        return wixData.update(request.query.collectionId, item)
                            .then((_) => {
                                res.status = res.body.status.code;
                                return response(res);
                            }).catch((err) => {
                                // COULD NOT UPDATE
                                console.log(err);
                                res.body.status.code = 500;
                                res.body.status.msg = err;
                                res.status = res.body.status.code;
                                return response(res);
                            });
                    }
                })
                .catch((err) => {
                    // NO RESULT
                    console.log(err);
                    res.body.status.code = 500;
                    res.body.status.msg = err;
                    res.status = res.body.status.code;
                    return response(res);
                });
        })
        .catch((err) => {
            // COULD NOT PARSE JSON
            console.log(err);
            res.body.status.code = 500;
            res.body.status.msg = err;
            res.status = res.body.status.code;
            return response(res);
        });
}

export function use_updateById(request) {
    return auth.validateJWT(request.query['jwt'], request.headers.authorization, (res) => {
        return request.body.text()
            .then((text) => {
                return wixData.query(request.query.collectionId)
                    .eq('objectId', request.query.objectId)
                    .find()
                    .then((result) => {
                        if (result.items.length == 0) {
                            res.body.status.code = 404;
                            res.body.status.msg = "No items in collection with a matching ID.";
                        } else {
                            res.body.status.code = 200;
                            res.body.status.msg = "OK";
                            var item = result.items.find(e => e['objectId'] == request.query.objectId);
                            var obj = JSON.parse(text);
                            var objKeys = Object.keys(obj);
                            for (const key of objKeys) {
                                item[key] = obj[key];
                            }
                            return wixData.update(request.query.collectionId, item)
                                .then((_) => {
                                    res.status = res.body.status.code;
                                    return response(res);
                                }).catch((err) => {
                                    // COULD NOT UPDATE
                                    console.log(err);
                                    res.body.status.code = 500;
                                    res.body.status.msg = err;
                                    res.status = res.body.status.code;
                                    return response(res);
                                });
                        }
                    })
                    .catch((err) => {
                        // NO RESULT
                        console.log(err);
                        res.body.status.code = 500;
                        res.body.status.msg = err;
                        res.status = res.body.status.code;
                        return response(res);
                    });
            })
            .catch((err) => {
                // COULD NOT PARSE JSON
                console.log(err);
                res.body.status.code = 500;
                res.body.status.msg = err;
                res.status = res.body.status.code;
                return response(res);
            });
    });
}

export function delete_deleteById(request) {
    return auth.validateJWT(request.query['jwt'], request.headers.authorization, (res) => {
        return wixData.query(request.query.collectionId)
            .eq('objectId', request.query.objectId)
            .find()
            .then((result) => {
                if (result.items.length == 0) {
                    res.status = res.body.status.code = 404;
                    res.body.status.msg = "No items in collection with a matching ID.";
                    return response(res);
                } else {
                    var obId = result['items'][0]['_id'];
                    return wixData.remove(request.query.collectionId, obId)
                        .then((_) => {
                            res.status = res.body.status.code = 200;
                            res.body.status.msg = "OK";
                            return response(res);
                        }).catch((err) => {
                            console.log(err);
                            res.status = res.body.status.code = 500;
                            res.body.status.msg = err;
                            return response(res);
                        });
                }
            }).catch((err) => {
                console.log(err);
                res.status = res.body.status.code = 500;
                res.body.status.msg = err;
                return response(res);
            });
    });
}