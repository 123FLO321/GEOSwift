//
//  Geometries.swift
//  GEOSwift
//
//  Created by Andrea Cremaschi on 10/06/15.
//  Copyright (c) 2015 andreacremaschi. All rights reserved.
//

import Foundation

public class Waypoint : Geometry {
    public let coordinate: Coordinate
    
    public override class func geometryTypeId() -> Int32 {
        return 0 // GEOS_POINT
    }
    
    public required init(GEOSGeom: COpaquePointer, destroyOnDeinit: Bool) {
        let isValid = GEOSGeom != nil && GEOSGeomTypeId_r(GEOS_HANDLE, GEOSGeom) == Waypoint.geometryTypeId() // GEOS_POINT
        
        if (!isValid) {
            coordinate = Coordinate(x: 0, y: 0)
        } else {
            let points = CoordinatesCollection(geometry: GEOSGeom)
            if points.count>0 {
                self.coordinate = points[0]
            } else {
                coordinate = Coordinate(x: 0, y: 0)
            }
        }
        super.init(GEOSGeom: GEOSGeom, destroyOnDeinit: destroyOnDeinit)
    }
    
    public convenience init?(WKT: String) {
        let GEOSGeom = GEOSGeomFromWKT(GEOS_HANDLE, WKT)
        
        if Geometry.classForGEOSGeom(GEOSGeom) !== Waypoint.self {
            self.init(GEOSGeom: nil)
            return nil
        }
        self.init(GEOSGeom: GEOSGeom, destroyOnDeinit: true)
    }
}

public class Polygon : Geometry {
    
    public override class func geometryTypeId() -> Int32 {
        return 3 // GEOS_POLYGON
    }
    
    public required init(GEOSGeom: COpaquePointer, destroyOnDeinit: Bool) {
        super.init(GEOSGeom: GEOSGeom, destroyOnDeinit: destroyOnDeinit)
    }
    
    private(set) public lazy var exteriorRing: LinearRing = {
        let exteriorRing = GEOSGetExteriorRing_r(GEOS_HANDLE, self.geometry)
        let linestring = Geometry.create(exteriorRing, destroyOnDeinit: false) as! LinearRing
        return linestring
        }()
    
    private(set) public lazy var interiorRings: [LinearRing] = {
        var interiorRings = [LinearRing]()
        let numInteriorRings = GEOSGetNumInteriorRings_r(GEOS_HANDLE, self.geometry)
        if numInteriorRings>0 {
            for index in 0...numInteriorRings-1 {
                let interiorRingGEOSGeom = GEOSGetInteriorRingN_r(GEOS_HANDLE, self.geometry, index)
                if let ring = Geometry.create(interiorRingGEOSGeom, destroyOnDeinit: false) as? LinearRing {
                    interiorRings.append(ring)
                }
            }
        }
        return interiorRings
        }()
    
    public convenience init?(WKT: String) {
        let GEOSGeom = GEOSGeomFromWKT(GEOS_HANDLE, WKT)
        
        if Geometry.classForGEOSGeom(GEOSGeom) !== Polygon.self {
            self.init(GEOSGeom: nil)
            return nil
        }
        self.init(GEOSGeom: GEOSGeom, destroyOnDeinit: true)
    }
    public convenience init?(shell: LinearRing, holes: Array<LinearRing>?) {
        // clone shell
        let shellGEOSGeom = GEOSGeom_clone_r(GEOS_HANDLE, shell.geometry)
        
        // clone holes
        if let holes = holes {
            var geometriesPointer = UnsafeMutablePointer<COpaquePointer>.alloc(holes.count)
            for (i, geom) in enumerate(holes) {
                let GEOSGeom = GEOSGeom_clone_r(GEOS_HANDLE, geom.geometry)
                geometriesPointer[i] = GEOSGeom
            }
            let geometry = GEOSGeom_createPolygon_r(GEOS_HANDLE, shellGEOSGeom, geometriesPointer, UInt32(holes.count))
            self.init(GEOSGeom: geometry, destroyOnDeinit: true)
            geometriesPointer.dealloc(holes.count)
        } else {
            let geometry = GEOSGeom_createPolygon_r(GEOS_HANDLE, shellGEOSGeom, nil, 0)
            self.init(GEOSGeom: geometry, destroyOnDeinit: true)
        }
    }
}

public class LineString : Geometry {
    
    public override class func geometryTypeId() -> Int32 {
        return 1 // GEOS_LINESTRING
    }
    
    private(set) public lazy var points: CoordinatesCollection = {
        return CoordinatesCollection(geometry: self.geometry)
        }()
    
    public convenience init?(WKT: String) {
        let GEOSGeom = GEOSGeomFromWKT(GEOS_HANDLE, WKT)
        
        if Geometry.classForGEOSGeom(GEOSGeom) !== LineString.self {
            self.init(GEOSGeom: nil)
            return nil
        }
        self.init(GEOSGeom: GEOSGeom, destroyOnDeinit: true)
    }
}

public class LinearRing : LineString {
    
}

public class GeometryCollection<T: Geometry> : Geometry {
    
    public override class func geometryTypeId() -> Int32 {
        return 7 // GEOS_LINESTRING
    }
    
    private(set) public lazy var geometries: GeometriesCollection<T> = {
        return GeometriesCollection<T>(geometry: self.geometry)
        }()
    public required init(GEOSGeom: COpaquePointer, destroyOnDeinit: Bool) {
        super.init(GEOSGeom: GEOSGeom, destroyOnDeinit: destroyOnDeinit)
    }
    private convenience init(GEOSGeom: COpaquePointer) {
        self.init(GEOSGeom: GEOSGeom, destroyOnDeinit: true)
    }
    
    public convenience init?(WKT: String) {
        let GEOSGeom = GEOSGeomFromWKT(GEOS_HANDLE, WKT)
        
        if Geometry.classForGEOSGeom(GEOSGeom) !== GeometryCollection.self {
            self.init(GEOSGeom: nil)
            return nil
        }
        self.init(GEOSGeom: GEOSGeom, destroyOnDeinit: true)
    }
    public convenience init?(geometries: Array<Geometry>) {
        var geometriesPointer = UnsafeMutablePointer<COpaquePointer>.alloc(geometries.count)
        for (i, geom) in enumerate(geometries) {
            let GEOSGeom = GEOSGeom_clone_r(GEOS_HANDLE, geom.geometry)
            geometriesPointer[i] = GEOSGeom
        }
        
        let geometry = GEOSGeom_createCollection_r(GEOS_HANDLE, self.dynamicType.geometryTypeId(), geometriesPointer, UInt32(geometries.count))
        self.init(GEOSGeom: geometry, destroyOnDeinit: true)
        geometriesPointer.dealloc(geometries.count)
    }
}

public class MultiLineString<T: LineString> : GeometryCollection<LineString> {
    
    public override class func geometryTypeId() -> Int32 {
        return 5 // GEOS_MULTILINESTRING
    }
    
    public required init(GEOSGeom: COpaquePointer, destroyOnDeinit: Bool) {
        super.init(GEOSGeom: GEOSGeom, destroyOnDeinit: destroyOnDeinit)
    }
    private convenience init(GEOSGeom: COpaquePointer) {
        self.init(GEOSGeom: GEOSGeom, destroyOnDeinit: true)
    }
    public convenience init?(WKT: String) {
        let GEOSGeom = GEOSGeomFromWKT(GEOS_HANDLE, WKT)
        
        if Geometry.classForGEOSGeom(GEOSGeom) !== MultiLineString.self {
            self.init(GEOSGeom: nil)
            return nil
        }
        self.init(GEOSGeom: GEOSGeom, destroyOnDeinit: true)
    }
    public convenience init?(linestrings: Array<LineString>) {
        var geometriesPointer = UnsafeMutablePointer<COpaquePointer>.alloc(linestrings.count)
        for (i, geom) in enumerate(linestrings) {
            let GEOSGeom = GEOSGeom_clone_r(GEOS_HANDLE, geom.geometry)
            geometriesPointer[i] = GEOSGeom
        }
        
        let geometry = GEOSGeom_createCollection_r(GEOS_HANDLE, self.dynamicType.geometryTypeId(), geometriesPointer, UInt32(linestrings.count))
        self.init(GEOSGeom: geometry, destroyOnDeinit: true)
        geometriesPointer.dealloc(linestrings.count)
    }
}

public class MultiPoint<T: Waypoint> : GeometryCollection<Waypoint> {
    public override class func geometryTypeId() -> Int32 {
        return 4 // GEOS_MULTIPOINT
    }
    public required init(GEOSGeom: COpaquePointer, destroyOnDeinit: Bool) {
        super.init(GEOSGeom: GEOSGeom, destroyOnDeinit: destroyOnDeinit)
    }
    private convenience init(GEOSGeom: COpaquePointer) {
        self.init(GEOSGeom: GEOSGeom, destroyOnDeinit: true)
    }
    public convenience init?(WKT: String) {
        let GEOSGeom = GEOSGeomFromWKT(GEOS_HANDLE, WKT)
        
        if Geometry.classForGEOSGeom(GEOSGeom) !== MultiPoint.self {
            self.init(GEOSGeom: nil)
            return nil
        }
        self.init(GEOSGeom: GEOSGeom, destroyOnDeinit: true)
    }
    public convenience init?(points: Array<Waypoint>) {
        var coordsPointer = UnsafeMutablePointer<COpaquePointer>.alloc(points.count)
        for (i, geom) in enumerate(points) {
            let GEOSGeom = GEOSGeom_clone_r(GEOS_HANDLE, geom.geometry)
            coordsPointer[i] = GEOSGeom
        }
        
        let geometry = GEOSGeom_createCollection_r(GEOS_HANDLE, self.dynamicType.geometryTypeId(), coordsPointer, UInt32(points.count))
        self.init(GEOSGeom: geometry, destroyOnDeinit: true)
        coordsPointer.dealloc(points.count)
    }
    
}

public class MultiPolygon<T: Polygon> : GeometryCollection<Polygon> {
    public override class func geometryTypeId() -> Int32 {
        return 6 // GEOS_MULTIPOLYGON
    }
    public required init(GEOSGeom: COpaquePointer, destroyOnDeinit: Bool) {
        super.init(GEOSGeom: GEOSGeom, destroyOnDeinit: destroyOnDeinit)
    }
    private convenience init(GEOSGeom: COpaquePointer) {
        self.init(GEOSGeom: GEOSGeom, destroyOnDeinit: true)
    }
    public convenience init?(WKT: String) {
        let GEOSGeom = GEOSGeomFromWKT(GEOS_HANDLE, WKT)
        
        if Geometry.classForGEOSGeom(GEOSGeom) !== MultiPolygon.self {
            self.init(GEOSGeom: nil)
            return nil
        }
        self.init(GEOSGeom: GEOSGeom, destroyOnDeinit: true)
    }
    public convenience init?(polygons: Array<Polygon>) {
        var coordsPointer = UnsafeMutablePointer<COpaquePointer>.alloc(polygons.count)
        for (i, geom) in enumerate(polygons) {
            let GEOSGeom = GEOSGeom_clone_r(GEOS_HANDLE, geom.geometry)
            coordsPointer[i] = GEOSGeom
        }
        
        let geometry = GEOSGeom_createCollection_r(GEOS_HANDLE, self.dynamicType.geometryTypeId(), coordsPointer, UInt32(polygons.count))
        self.init(GEOSGeom: geometry, destroyOnDeinit: true)
        coordsPointer.dealloc(polygons.count)
    }
}
