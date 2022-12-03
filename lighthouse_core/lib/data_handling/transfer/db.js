import { ok, notFound, serverError, badRequest, created, forbidden, response } from 'wix-http-functions';
import wixData from 'wix-data';
import { getSecret } from 'wix-secrets-backend';
import * as jwt from 'jsonwebtoken';

// https://infinitumlabsinc.editorx.io/lighthousecloud/_functions/getById

const options = {
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
};

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
    var res = options;
    wixData.query("Users")
        .contains("emailAddress", request.query.emailAddress)
        // .contains("password", request.query.password) // to detect incorrect password
        .find()
        .then((result) => {
            if (result.items.length == 0) {
                res.body.status.code = 404;
                res.body.status.msg = "No users with that email address";
            } else {
                var item = result.items[0];
                if (request.query.password == item['password']) {
                    res.body.status.code = 200;
                    res.body.status.msg = "OK";
                    getSecret('jwt_private_key').then((secret) => {
                        const jwtBearerToken = jwt.sign({}, secret, {
                            algorithm: 'RS256',
                            expiresIn: 120,
                            subject: item['objectId']
                        });
                        res.headers.Authorization = jwtBearerToken;
                    }).catch((err) => {
                        console.log(err);
                    });
                } else {
                    res.body.status.code = 403;
                    res.body.status.msg = "Incorrect password";
                }
            }
        }).catch((err) => {
            console.log(err);
            res.body.status.code = 500;
            res.body.status.msg = err;
        });

    res.status = res.body.status.code;
    return response(res);
}

export function get_getById(request) {
    var res = options;
    wixData.query(request.query.collectionId)
        .eq('objectId', request.query.objectId)
        .find()
        .then((result) => {
            if (result.items.length == 0) {
                res.body.status.code = 404;
                res.body.status.msg = "No items in collection with a matching ID.";
            } else {
                res.body.status.code = 200;
                res.body.status.msg = "OK";
                res.body.payload = result.items;
            }
        }).catch((err) => {
            console.log(err);
            res.body.status.code = 500;
            res.body.status.msg = err;
        });

    res.status = res.body.status.code;
    return response(res);
}

export function get_bulkGetByFilter(request) {
    var res = options;
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
}

export function post_create(request) {
    var res = options;
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
}

export function post_bulkCreate(request) {
    var res = options;
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
}

export function use_replaceById(request) {
    // unverified endpoint
    var res = options;
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
    var res = options;
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
}

export function delete_deleteById(request) {
    var res = options;
    wixData.query(request.query.collectionId)
        .eq('objectId', request.query.objectId)
        .find()
        .then((result) => {
            if (result.items.length == 0) {
                res.body.status.code = 404;
                res.body.status.msg = "No items in collection with a matching ID.";
            } else {
                var obId = result['items'][0]['_id'];
                wixData.remove(request.query.collectionId, obId)
                    .then((_) => {
                        res.body.status.code = 200;
                        res.body.status.msg = "OK";
                    }).catch((err) => {
                        console.log(err);
                        res.body.status.code = 500;
                        res.body.status.msg = err;
                    });
            }
        }).catch((err) => {
            console.log(err);
            res.body.status.code = 500;
            res.body.status.msg = err;
        });

    res.status = res.body.status.code;
    return response(res);
}