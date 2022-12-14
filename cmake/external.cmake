# This file is part of COMP_hack.
#
# Copyright (C) 2010-2016 COMP_hack Team <compomega@tutanota.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Enable the ExternalProject CMake module.
INCLUDE(ExternalProject)

OPTION(GIT_DEPENDENCIES "Download dependencies from Git instead." OFF)

IF(WIN32)
    SET(CMAKE_RELWITHDEBINFO_OPTIONS -DCMAKE_RELWITHDEBINFO_POSTFIX=_reldeb)
ENDIF(WIN32)

IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/GSL.zip")
    SET(GSL_URL
        URL "${CMAKE_SOURCE_DIR}/deps/GSL.zip"
    )
ELSEIF(GIT_DEPENDENCIES)
    SET(GSL_URL
        GIT_REPOSITORY https://github.com/Microsoft/GSL.git
        GIT_TAG master
    )
ELSE()
    SET(GSL_URL
        URL https://github.com/Microsoft/GSL/archive/5905d2d77467d9daa18fe711b55e2db7a30fe3e3.zip
        URL_HASH SHA1=a2d2c6bfe101be3ef80d9c69e3361f164517e7b9
    )
ENDIF()

ExternalProject_Add(
    gsl

    ${GSL_URL}

    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/gsl
    CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>

    # Dump output to a log instead of the screen.
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON

    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

ExternalProject_Get_Property(gsl SOURCE_DIR)
ExternalProject_Get_Property(gsl INSTALL_DIR)

SET_TARGET_PROPERTIES(gsl PROPERTIES FOLDER "Dependencies")

#SET(GSL_INCLUDE_DIRS "${INSTALL_DIR}/include")
SET(GSL_INCLUDE_DIRS "${SOURCE_DIR}/include")

FILE(MAKE_DIRECTORY "${GSL_INCLUDE_DIRS}")

IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/zlib.zip")
    SET(ZLIB_URL
        URL "${CMAKE_SOURCE_DIR}/deps/zlib.zip"
    )
ELSEIF(GIT_DEPENDENCIES)
    SET(ZLIB_URL
        GIT_REPOSITORY https://github.com/comphack/zlib.git
        GIT_TAG comp_hack
    )
ELSE()
    SET(ZLIB_URL
        URL https://github.com/comphack/zlib/archive/comp_hack-20180425.zip
        URL_HASH SHA1=41ef62fec86b9a4408d99c2e7ee1968a5e246e3b
    )
ENDIF()

ExternalProject_Add(
    zlib-lib

    ${ZLIB_URL}

    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/zlib
    CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> -DSKIP_INSTALL_FILES=ON -DUSE_STATIC_RUNTIME=${USE_STATIC_RUNTIME}

    # Dump output to a log instead of the screen.
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/libz.a
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/zlibstatic.lib
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/zlibstaticd.lib
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/zlibstatic_reldeb.lib
)

ExternalProject_Get_Property(zlib-lib INSTALL_DIR)

SET_TARGET_PROPERTIES(zlib-lib PROPERTIES FOLDER "Dependencies")

SET(ZLIB_INCLUDES "${INSTALL_DIR}/include")
SET(ZLIB_LIBRARIES zlib)

FILE(MAKE_DIRECTORY "${ZLIB_INCLUDES}")

ADD_LIBRARY(zlib STATIC IMPORTED)
ADD_DEPENDENCIES(zlib zlib-lib)

IF(WIN32)
    SET(ZLIB_LIBRARY "${INSTALL_DIR}/lib/zlibstatic_reldeb.lib")
    SET_TARGET_PROPERTIES(zlib PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/zlibstatic.lib"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/zlibstatic_reldeb.lib"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/zlibstaticd.lib")
ELSE()
    SET(ZLIB_LIBRARY "${INSTALL_DIR}/lib/libz.a")
    SET_TARGET_PROPERTIES(zlib PROPERTIES
        IMPORTED_LOCATION "${INSTALL_DIR}/lib/libz.a")
ENDIF()

SET_TARGET_PROPERTIES(zlib PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${ZLIB_INCLUDES}")

OPTION(USE_SYSTEM_OPENSSL "Build with the system OpenSSL library." OFF)

IF(USE_SYSTEM_OPENSSL)
    IF(WIN32)
        SET(OPENSSL_USE_STATIC_LIBS TRUE)

        IF(USE_STATIC_RUNTIME)
            SET(OPENSSL_MSVC_STATIC_RT TRUE)
        ENDIF(USE_STATIC_RUNTIME)
    ENDIF(WIN32)

    FIND_PACKAGE(OpenSSL)
ENDIF(USE_SYSTEM_OPENSSL)

IF(OPENSSL_FOUND)
    ADD_CUSTOM_TARGET(openssl)

    ADD_LIBRARY(ssl STATIC IMPORTED)
    SET_TARGET_PROPERTIES(ssl PROPERTIES IMPORTED_LOCATION
        "${OPENSSL_SSL_LIBRARY}")
    SET_TARGET_PROPERTIES(ssl PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}")

    ADD_LIBRARY(crypto STATIC IMPORTED)
    SET_TARGET_PROPERTIES(crypto PROPERTIES IMPORTED_LOCATION
        "${OPENSSL_CRYPTO_LIBRARY}")
    SET_TARGET_PROPERTIES(crypto PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}")
ELSE(OPENSSL_FOUND)
    IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/openssl.zip")
        SET(OPENSSL_URL
            URL "${CMAKE_SOURCE_DIR}/deps/openssl.zip"
        )
    ELSEIF(GIT_DEPENDENCIES)
        SET(OPENSSL_URL
            GIT_REPOSITORY https://github.com/comphack/openssl.git
            GIT_TAG comp_hack
        )
    ELSE()
        SET(OPENSSL_URL
            URL https://github.com/comphack/openssl/archive/comp_hack-20180424.zip
            URL_HASH SHA1=0ac698894a8d9566a8d7982e32869252dc11d18b
        )
    ENDIF()

    ExternalProject_Add(
        openssl

        ${OPENSSL_URL}

        PREFIX ${CMAKE_CURRENT_BINARY_DIR}/openssl
        CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> -DUSE_STATIC_RUNTIME=${USE_STATIC_RUNTIME} -DCMAKE_DEBUG_POSTFIX=d -DBUILD_VALGRIND_FRIENDLY=${BUILD_VALGRIND_FRIENDLY}

        # Dump output to a log instead of the screen.
        LOG_DOWNLOAD ON
        LOG_CONFIGURE ON
        LOG_BUILD ON
        LOG_INSTALL ON

        BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ssl${CMAKE_STATIC_LIBRARY_SUFFIX}
        BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}crypto${CMAKE_STATIC_LIBRARY_SUFFIX}

        BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ssleay32${CMAKE_STATIC_LIBRARY_SUFFIX}
        BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}libeay32${CMAKE_STATIC_LIBRARY_SUFFIX}

        BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ssleay32d${CMAKE_STATIC_LIBRARY_SUFFIX}
        BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}libeay32d${CMAKE_STATIC_LIBRARY_SUFFIX}

        BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ssleay32_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
        BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}libeay32_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
    )

    ExternalProject_Get_Property(openssl INSTALL_DIR)

    SET_TARGET_PROPERTIES(openssl PROPERTIES FOLDER "Dependencies")

    SET(OPENSSL_INCLUDE_DIR "${INSTALL_DIR}/include")
    SET(OPENSSL_ROOT_DIR "${INSTALL_DIR}")

    FILE(MAKE_DIRECTORY "${OPENSSL_INCLUDE_DIR}")

    IF(WIN32)
        SET(OPENSSL_LIBRARIES ssleay32 libeay32 crypt32)
    ELSE()
        SET(OPENSSL_LIBRARIES ssl crypto)
    ENDIF()

    IF(WIN32)
        ADD_LIBRARY(ssleay32 STATIC IMPORTED)
        ADD_DEPENDENCIES(ssleay32 openssl)
        SET_TARGET_PROPERTIES(ssleay32 PROPERTIES
            IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ssleay32${CMAKE_STATIC_LIBRARY_SUFFIX}"
            IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ssleay32_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
            IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ssleay32d${CMAKE_STATIC_LIBRARY_SUFFIX}")

        SET_TARGET_PROPERTIES(ssleay32 PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}")

        ADD_LIBRARY(libeay32 STATIC IMPORTED)
        ADD_DEPENDENCIES(libeay32 openssl)
        SET_TARGET_PROPERTIES(libeay32 PROPERTIES
            IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}libeay32${CMAKE_STATIC_LIBRARY_SUFFIX}"
            IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}libeay32_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
            IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}libeay32d${CMAKE_STATIC_LIBRARY_SUFFIX}")

        SET_TARGET_PROPERTIES(libeay32 PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}")
    ELSE()
        ADD_LIBRARY(ssl STATIC IMPORTED)
        ADD_DEPENDENCIES(ssl openssl)
        SET_TARGET_PROPERTIES(ssl PROPERTIES IMPORTED_LOCATION
            "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ssl${CMAKE_STATIC_LIBRARY_SUFFIX}")

        SET_TARGET_PROPERTIES(ssl PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}")

        ADD_LIBRARY(crypto STATIC IMPORTED)
        ADD_DEPENDENCIES(crypto openssl)
        SET_TARGET_PROPERTIES(crypto PROPERTIES IMPORTED_LOCATION
            "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}crypto${CMAKE_STATIC_LIBRARY_SUFFIX}")

        SET_TARGET_PROPERTIES(crypto PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}")
    ENDIF()
ENDIF(OPENSSL_FOUND)

IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/mariadb.zip")
    SET(MARIADB_URL
        URL "${CMAKE_SOURCE_DIR}/deps/mariadb.zip"
    )
ELSEIF(GIT_DEPENDENCIES)
    SET(MARIADB_URL
        GIT_REPOSITORY https://github.com/comphack/mariadb.git
        GIT_TAG comp_hack
    )
ELSE()
    SET(MARIADB_URL
        URL https://github.com/comphack/mariadb/archive/comp_hack-20220723.zip
        URL_HASH SHA1=01167c8b54763c27df025dae49c057624175ffe8
    )
ENDIF()

ExternalProject_Add(
    mariadb

    ${MARIADB_URL}

    DEPENDS openssl

    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/mariadb
    CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> "-DCMAKE_CXX_FLAGS=-std=c++11 ${SPECIAL_COMPILER_FLAGS}" "-DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}" -DUSE_STATIC_RUNTIME=${USE_STATIC_RUNTIME} -DCMAKE_DEBUG_POSTFIX=d -DWITH_OPENSSL=ON -DUSE_SYSTEM_OPENSSL=${USE_SYSTEM_OPENSSL}

    # Dump output to a log instead of the screen.
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/mariadb/${CMAKE_STATIC_LIBRARY_PREFIX}mariadbclient${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/mariadb/${CMAKE_STATIC_LIBRARY_PREFIX}mariadbclientd${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/mariadb/${CMAKE_STATIC_LIBRARY_PREFIX}mariadbclient_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
)

ExternalProject_Get_Property(mariadb INSTALL_DIR)

SET_TARGET_PROPERTIES(mariadb PROPERTIES FOLDER "Dependencies")

SET(MARIADB_INCLUDE_DIRS "${INSTALL_DIR}/include/mariadb")

FILE(MAKE_DIRECTORY "${MARIADB_INCLUDE_DIRS}")

ADD_LIBRARY(mariadbclient STATIC IMPORTED)
ADD_DEPENDENCIES(mariadbclient mariadb)

IF(WIN32)
    SET_TARGET_PROPERTIES(mariadbclient PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/mariadb/${CMAKE_STATIC_LIBRARY_PREFIX}mariadbclient${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/mariadb/${CMAKE_STATIC_LIBRARY_PREFIX}mariadbclient_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/mariadb/${CMAKE_STATIC_LIBRARY_PREFIX}mariadbclientd${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(mariadbclient PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/mariadb/${CMAKE_STATIC_LIBRARY_PREFIX}mariadbclient${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(mariadbclient PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${MARIADB_INCLUDE_DIRS}")

IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/ttvfs.zip")
    SET(TTVFS_URL
        URL "${CMAKE_SOURCE_DIR}/deps/ttvfs.zip"
    )
ELSEIF(GIT_DEPENDENCIES)
    SET(TTVFS_URL
        GIT_REPOSITORY https://github.com/comphack/ttvfs.git
        GIT_TAG comp_hack
    )
ELSE()
    SET(TTVFS_URL
        URL https://github.com/comphack/ttvfs/archive/comp_hack-20180424.zip
        URL_HASH SHA1=c3feca3b35109e9ad4ae61821f62df76a412b87f
    )
ENDIF()

ExternalProject_Add(
    ttvfs-ex

    ${TTVFS_URL}

    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/ttvfs
    CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> "-DCMAKE_CXX_FLAGS=-std=c++11 ${SPECIAL_COMPILER_FLAGS}" -DUSE_STATIC_RUNTIME=${USE_STATIC_RUNTIME} -DCMAKE_DEBUG_POSTFIX=d

    # Dump output to a log instead of the screen.
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_cfileapi${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_zip${CMAKE_STATIC_LIBRARY_SUFFIX}

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfsd${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_cfileapid${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_zipd${CMAKE_STATIC_LIBRARY_SUFFIX}

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_cfileapi_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_zip_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
)

ExternalProject_Get_Property(ttvfs-ex INSTALL_DIR)

SET_TARGET_PROPERTIES(ttvfs-ex PROPERTIES FOLDER "Dependencies")

SET(TTVFS_INCLUDE_DIRS "${INSTALL_DIR}/include")

FILE(MAKE_DIRECTORY "${TTVFS_INCLUDE_DIRS}")

ADD_LIBRARY(ttvfs STATIC IMPORTED)
ADD_DEPENDENCIES(ttvfs ttvfs-ex)

IF(WIN32)
    SET_TARGET_PROPERTIES(ttvfs PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfsd${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(ttvfs PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(ttvfs PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${TTVFS_INCLUDE_DIRS}")

ADD_LIBRARY(ttvfs_cfileapi STATIC IMPORTED)
ADD_DEPENDENCIES(ttvfs_cfileapi ttvfs-ex)

IF(WIN32)
    SET_TARGET_PROPERTIES(ttvfs_cfileapi PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_cfileapi${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_cfileapi_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_cfileapid${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(ttvfs_cfileapi PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_cfileapi${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(ttvfs_cfileapi PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${TTVFS_INCLUDE_DIRS}")

ADD_LIBRARY(ttvfs_zip STATIC IMPORTED)
ADD_DEPENDENCIES(ttvfs_zip ttvfs-ex)

IF(WIN32)
    SET_TARGET_PROPERTIES(ttvfs_zip PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_zip${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_zip_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_zipd${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(ttvfs_zip PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ttvfs_zip${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(ttvfs_zip PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${TTVFS_INCLUDE_DIRS}")

SET(TTVFS_GEN_PATH "${INSTALL_DIR}/bin/ttvfs_gen")

IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/physfs.zip")
    SET(PHYSFS_URL
        URL "${CMAKE_SOURCE_DIR}/deps/physfs.zip"
    )
ELSEIF(GIT_DEPENDENCIES)
    SET(PHYSFS_URL
        GIT_REPOSITORY https://github.com/comphack/physfs.git
        GIT_TAG comp_hack
    )
ELSE()
    SET(PHYSFS_URL
        URL https://github.com/comphack/physfs/archive/comp_hack-20180424.zip
        URL_HASH SHA1=46de8609129749fccd8bbed02b68d6966ebb5e9b
    )
ENDIF()

ExternalProject_Add(
    physfs-lib

    ${PHYSFS_URL}

    DEPENDS zlib

    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/physfs
    CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> "-DCMAKE_CXX_FLAGS=-std=c++11 ${SPECIAL_COMPILER_FLAGS}" -DUSE_STATIC_RUNTIME=${USE_STATIC_RUNTIME} -DCMAKE_DEBUG_POSTFIX=d -DPHYSFS_ARCHIVE_ZIP=TRUE -DPHYSFS_ARCHIVE_7Z=FALSE -DPHYSFS_ARCHIVE_GRP=FALSE -DPHYSFS_ARCHIVE_WAD=FALSE -DPHYSFS_ARCHIVE_HOG=FALSE -DPHYSFS_ARCHIVE_MVL=FALSE -DPHYSFS_ARCHIVE_QPAK=FALSE -DPHYSFS_BUILD_STATIC=TRUE -DPHYSFS_BUILD_SHARED=FALSE -DPHYSFS_BUILD_TEST=FALSE -DPHYSFS_BUILD_WX_TEST=FALSE -DPHYSFS_INTERNAL_ZLIB=FALSE "-DZLIB_LIBRARY=${ZLIB_LIBRARY}" "-DZLIB_INCLUDE_DIR=${ZLIB_INCLUDES}"

    # Dump output to a log instead of the screen.
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}physfs${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}physfsd${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}physfs_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
)

ExternalProject_Get_Property(physfs-lib INSTALL_DIR)

SET_TARGET_PROPERTIES(physfs-lib PROPERTIES FOLDER "Dependencies")

SET(PHYSFS_INCLUDE_DIRS "${INSTALL_DIR}/include")

FILE(MAKE_DIRECTORY "${PHYSFS_INCLUDE_DIRS}")

ADD_LIBRARY(physfs STATIC IMPORTED)
ADD_DEPENDENCIES(physfs physfs-lib)

IF(WIN32)
    SET_TARGET_PROPERTIES(physfs PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}physfs${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}physfs_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}physfsd${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(physfs PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}physfs${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(physfs PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${PHYSFS_INCLUDE_DIRS}")

IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/civetweb.zip")
    SET(CIVET_URL
        URL "${CMAKE_SOURCE_DIR}/deps/civetweb.zip"
    )
ELSEIF(GIT_DEPENDENCIES)
    SET(CIVET_URL
        GIT_REPOSITORY https://github.com/comphack/civetweb.git
        GIT_TAG comp_hack
    )
ELSE()
    SET(CIVET_URL
        URL https://github.com/comphack/civetweb/archive/comp_hack-20201128.zip
        URL_HASH SHA1=2501b0296c41d7b2a0375fa3772d56ea175450fe
    )
ENDIF()

ExternalProject_Add(
    civet

    ${CIVET_URL}

    DEPENDS openssl

    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/civetweb
    CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> "-DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}" -DBUILD_TESTING=OFF -DCIVETWEB_LIBRARIES_ONLY=ON -DCIVETWEB_ENABLE_SLL=ON -DCIVETWEB_ENABLE_SSL_DYNAMIC_LOADING=OFF -DCIVETWEB_ALLOW_WARNINGS=ON -DCIVETWEB_ENABLE_CXX=ON "-DCMAKE_CXX_FLAGS=-std=c++11 ${SPECIAL_COMPILER_FLAGS}" -DUSE_STATIC_RUNTIME=${USE_STATIC_RUNTIME} -DCMAKE_DEBUG_POSTFIX=d -DUSE_SYSTEM_OPENSSL=${USE_SYSTEM_OPENSSL}

    # Dump output to a log instead of the screen.
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}civetweb${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}cxx-library${CMAKE_STATIC_LIBRARY_SUFFIX}

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}civetwebd${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}cxx-libraryd${CMAKE_STATIC_LIBRARY_SUFFIX}

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}civetweb_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}cxx-library_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
)

ExternalProject_Get_Property(civet INSTALL_DIR)

SET_TARGET_PROPERTIES(civet PROPERTIES FOLDER "Dependencies")

SET(CIVETWEB_INCLUDE_DIRS "${INSTALL_DIR}/include")

FILE(MAKE_DIRECTORY "${CIVETWEB_INCLUDE_DIRS}")

ADD_LIBRARY(civetweb STATIC IMPORTED)
ADD_DEPENDENCIES(civetweb civet)

IF(WIN32)
    SET_TARGET_PROPERTIES(civetweb PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}civetweb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}civetweb_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}civetwebd${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(civetweb PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}civetweb${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(civetweb PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${CIVETWEB_INCLUDE_DIRS}")

ADD_LIBRARY(civetweb-cxx STATIC IMPORTED)
ADD_DEPENDENCIES(civetweb-cxx civetweb)

IF(WIN32)
    SET_TARGET_PROPERTIES(civetweb-cxx PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}cxx-library${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}cxx-library_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}cxx-libraryd${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(civetweb-cxx PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}cxx-library${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(civetweb-cxx PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${CIVETWEB_INCLUDE_DIRS}")

IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/squirrel3.zip")
    SET(SQUIRREL_URL
        URL "${CMAKE_SOURCE_DIR}/deps/squirrel3.zip"
    )
ELSEIF(GIT_DEPENDENCIES)
    SET(SQUIRREL_URL
        GIT_REPOSITORY https://github.com/comphack/squirrel3.git
        GIT_TAG comp_hack
    )
ELSE()
    SET(SQUIRREL_URL
        URL https://github.com/comphack/squirrel3/archive/comp_hack-20200402.zip
        URL_HASH SHA1=d14c0d79738ce773edfcb2a67cdfd699cf665d3a
    )
ENDIF()

ExternalProject_Add(
    squirrel3

    ${SQUIRREL_URL}

    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/squirrel3
    CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> "-DCMAKE_CXX_FLAGS=-std=c++11 ${SPECIAL_COMPILER_FLAGS}" -DUSE_STATIC_RUNTIME=${USE_STATIC_RUNTIME} -DCMAKE_DEBUG_POSTFIX=d

    # Dump output to a log instead of the screen.
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}squirrel${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}sqstdlib${CMAKE_STATIC_LIBRARY_SUFFIX}

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}squirreld${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}sqstdlibd${CMAKE_STATIC_LIBRARY_SUFFIX}

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}squirrel_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}sqstdlib_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
)

ExternalProject_Get_Property(squirrel3 INSTALL_DIR)

SET_TARGET_PROPERTIES(squirrel3 PROPERTIES FOLDER "Dependencies")

SET(SQUIRREL_INCLUDE_DIRS "${INSTALL_DIR}/include")

FILE(MAKE_DIRECTORY "${SQUIRREL_INCLUDE_DIRS}")

ADD_LIBRARY(squirrel STATIC IMPORTED)
ADD_DEPENDENCIES(squirrel squirrel3)

IF(WIN32)
    SET_TARGET_PROPERTIES(squirrel PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}squirrel${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}squirrel_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}squirreld${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(squirrel PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}squirrel${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(squirrel PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
    "${SQUIRREL_INCLUDE_DIRS}")

ADD_LIBRARY(sqstdlib STATIC IMPORTED)
ADD_DEPENDENCIES(sqstdlib squirrel3)

IF(WIN32)
    SET_TARGET_PROPERTIES(sqstdlib PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}sqstdlib${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}sqstdlib_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}sqstdlibd${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(sqstdlib PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}sqstdlib${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(sqstdlib PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
    "${SQUIRREL_INCLUDE_DIRS}")

IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/asio.zip")
    SET(ASIO_URL
        URL "${CMAKE_SOURCE_DIR}/deps/asio.zip"
    )
ELSEIF(GIT_DEPENDENCIES)
    SET(ASIO_URL
        GIT_REPOSITORY https://github.com/comphack/asio.git
        GIT_TAG comp_hack
    )
ELSE()
    SET(ASIO_URL
        URL https://github.com/comphack/asio/archive/comp_hack-20200402.zip
        URL_HASH SHA1=26d1af5e88ae4e0e93f64d614cd5f59ba13a024d
    )
ENDIF()

ExternalProject_Add(
    asio

    ${ASIO_URL}

    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/asio
    CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> "-DCMAKE_CXX_FLAGS=-std=c++11 ${SPECIAL_COMPILER_FLAGS}" -DUSE_STATIC_RUNTIME=${USE_STATIC_RUNTIME} -DCMAKE_DEBUG_POSTFIX=d

    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""

    # Dump output to a log instead of the screen.
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

ExternalProject_Get_Property(asio INSTALL_DIR)

SET_TARGET_PROPERTIES(asio PROPERTIES FOLDER "Dependencies")

SET(ASIO_INCLUDE_DIRS "${INSTALL_DIR}/src/asio/asio/include")

FILE(MAKE_DIRECTORY "${ASIO_INCLUDE_DIRS}")

IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/tinyxml2.zip")
    SET(TINYXML2_URL
        URL "${CMAKE_SOURCE_DIR}/deps/tinyxml2.zip"
    )
ELSEIF(GIT_DEPENDENCIES)
    SET(TINYXML2_URL
        GIT_REPOSITORY https://github.com/comphack/tinyxml2.git
        GIT_TAG comp_hack
    )
ELSE()
    SET(TINYXML2_URL
        URL https://github.com/comphack/tinyxml2/archive/comp_hack-20200318.zip
        URL_HASH SHA1=bccb54ff37d0076424da4a28a302515eef2f3981
    )
ENDIF()

ExternalProject_Add(
    tinyxml2-ex

    ${TINYXML2_URL}

    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/tinyxml2
    CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF "-DCMAKE_CXX_FLAGS=-std=c++11 ${SPECIAL_COMPILER_FLAGS}" -DUSE_STATIC_RUNTIME=${USE_STATIC_RUNTIME} -DCMAKE_DEBUG_POSTFIX=d

    # Dump output to a log instead of the screen.
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}tinyxml2${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}tinyxml2d${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}tinyxml2_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
)

ExternalProject_Get_Property(tinyxml2-ex INSTALL_DIR)

SET_TARGET_PROPERTIES(tinyxml2-ex PROPERTIES FOLDER "Dependencies")

SET(TINYXML2_INCLUDE_DIRS "${INSTALL_DIR}/include")

FILE(MAKE_DIRECTORY "${TINYXML2_INCLUDE_DIRS}")

ADD_LIBRARY(tinyxml2 STATIC IMPORTED)
ADD_DEPENDENCIES(tinyxml2 tinyxml2-ex)

IF(WIN32)
    SET_TARGET_PROPERTIES(tinyxml2 PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}tinyxml2${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}tinyxml2_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}tinyxml2d${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(tinyxml2 PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}tinyxml2${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(tinyxml2 PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${TINYXML2_INCLUDE_DIRS}")

IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/googletest.zip")
    SET(GOOGLETEST_URL
        URL "${CMAKE_SOURCE_DIR}/deps/googletest.zip"
    )
ELSEIF(GIT_DEPENDENCIES)
    SET(GOOGLETEST_URL
        GIT_REPOSITORY https://github.com/comphack/googletest.git
        GIT_TAG comp_hack
    )
ELSE()
    SET(GOOGLETEST_URL
        URL https://github.com/comphack/googletest/archive/comp_hack-20200318.zip
        URL_HASH SHA1=5a87ec2b8f58ecc187dcf899b1457dfbc873d6fd
    )
ENDIF()

ExternalProject_Add(
    googletest

    ${GOOGLETEST_URL}

    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/googletest
    CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> "-DCMAKE_CXX_FLAGS=-std=c++11 ${SPECIAL_COMPILER_FLAGS}" -DUSE_STATIC_RUNTIME=${USE_STATIC_RUNTIME} -DCMAKE_DEBUG_POSTFIX=d

    # Dump output to a log instead of the screen.
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gtest${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmock${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmock_main${CMAKE_STATIC_LIBRARY_SUFFIX}

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gtestd${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmockd${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmock_maind${CMAKE_STATIC_LIBRARY_SUFFIX}

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gtest_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmock_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmock_main_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
)

ExternalProject_Get_Property(googletest INSTALL_DIR)

SET_TARGET_PROPERTIES(googletest PROPERTIES FOLDER "Dependencies")

SET(GTEST_INCLUDE_DIRS "${INSTALL_DIR}/include")

FILE(MAKE_DIRECTORY "${GTEST_INCLUDE_DIRS}")

ADD_LIBRARY(gtest STATIC IMPORTED)
ADD_DEPENDENCIES(gtest googletest)

IF(WIN32)
    SET_TARGET_PROPERTIES(gtest PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gtest${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gtest_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gtestd${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(gtest PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gtest${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(gtest PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${GTEST_INCLUDE_DIRS}")

ADD_LIBRARY(gmock STATIC IMPORTED)
ADD_DEPENDENCIES(gmock googletest)

IF(WIN32)
    SET_TARGET_PROPERTIES(gmock PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmock${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmock_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmockd${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(gmock PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmock${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(gmock PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${GTEST_INCLUDE_DIRS}")

ADD_LIBRARY(gmock_main STATIC IMPORTED)
ADD_DEPENDENCIES(gmock_main googletest)

IF(WIN32)
    SET_TARGET_PROPERTIES(gmock_main PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmock_main${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmock_main_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmock_maind${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(gmock_main PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gmock_main${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(gmock_main PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${GTEST_INCLUDE_DIRS}")

SET(GMOCK_DIR "${INSTALL_DIR}")

IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/JsonBox.zip")
    SET(JSONBOX_URL
        URL "${CMAKE_SOURCE_DIR}/deps/JsonBox.zip"
    )
ELSEIF(GIT_DEPENDENCIES)
    SET(JSONBOX_URL
        GIT_REPOSITORY https://github.com/comphack/JsonBox.git
        GIT_TAG comp_hack
    )
ELSE()
    SET(JSONBOX_URL
        URL https://github.com/comphack/JsonBox/archive/comp_hack-20180424.zip
        URL_HASH SHA1=60fce942f5910a6da8db27d4dcb894ea28adea57
    )
ENDIF()

ExternalProject_Add(
    jsonbox-ex

    ${JSONBOX_URL}

    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/JsonBox
    CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> -DBUILD_SHARED_LIBS=OFF "-DCMAKE_CXX_FLAGS=-std=c++11 ${SPECIAL_COMPILER_FLAGS}" -DUSE_STATIC_RUNTIME=${USE_STATIC_RUNTIME} -DCMAKE_DEBUG_POSTFIX=d

    # Dump output to a log instead of the screen.
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}JsonBox${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}JsonBoxd${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}JsonBox_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
)

ExternalProject_Get_Property(jsonbox-ex INSTALL_DIR)

SET_TARGET_PROPERTIES(jsonbox-ex PROPERTIES FOLDER "Dependencies")

SET(JSONBOX_INCLUDE_DIRS "${INSTALL_DIR}/include")

FILE(MAKE_DIRECTORY "${JSONBOX_INCLUDE_DIRS}")

ADD_LIBRARY(jsonbox STATIC IMPORTED)
ADD_DEPENDENCIES(jsonbox jsonbox-ex)

IF(WIN32)
    SET_TARGET_PROPERTIES(jsonbox PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}JsonBox${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}JsonBox_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}JsonBoxd${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(jsonbox PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}JsonBox${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(jsonbox PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${JSONBOX_INCLUDE_DIRS}")

IF(EXISTS "${CMAKE_SOURCE_DIR}/deps/yaml-cpp.zip")
    SET(YAML_CPP_URL
        URL "${CMAKE_SOURCE_DIR}/deps/yaml-cpp.zip"
    )
ELSEIF(GIT_DEPENDENCIES)
    SET(YAML_CPP_URL
        GIT_REPOSITORY https://github.com/comphack/yaml-cpp.git
        GIT_TAG comp_hack
    )
ELSE()
    SET(YAML_CPP_URL
        URL https://github.com/comphack/yaml-cpp/archive/comp_hack-20220723.zip
        URL_HASH SHA1=a96d9e21584920a1360aa14320d6c05f2b548f6b
    )
ENDIF()

ExternalProject_Add(
    yaml-cpp-lib

    ${YAML_CPP_URL}

    DEPENDS zlib

    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/yaml-cpp
    CMAKE_ARGS ${CMAKE_RELWITHDEBINFO_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> -DYAML_CPP_BUILD_CONTRIB=OFF -DYAML_CPP_BUILD_TOOLS=OFF -DYAML_BUILD_SHARED_LIBS=OFF -DYAML_CPP_BUILD_TESTS=OFF -DYAML_MSVC_SHARED_RT=$<NOT:$<BOOL:${USE_STATIC_RUNTIME}>>

    # Dump output to a log instead of the screen.
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON

    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}yaml-cpp${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}yaml-cppd${CMAKE_STATIC_LIBRARY_SUFFIX}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}yaml-cpp_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}
)

ExternalProject_Get_Property(yaml-cpp-lib INSTALL_DIR)

SET_TARGET_PROPERTIES(yaml-cpp-lib PROPERTIES FOLDER "Dependencies")

SET(YAML_CPP_INCLUDES "${INSTALL_DIR}/include")
SET(YAML_CPP_LIBRARIES yaml-cpp)

FILE(MAKE_DIRECTORY "${YAML_CPP_INCLUDES}")

ADD_LIBRARY(yaml-cpp STATIC IMPORTED)
ADD_DEPENDENCIES(yaml-cpp yaml-cpp-lib)

IF(WIN32)
    SET_TARGET_PROPERTIES(yaml-cpp PROPERTIES
        IMPORTED_LOCATION_RELEASE "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}yaml-cpp${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_RELWITHDEBINFO "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}yaml-cpp_reldeb${CMAKE_STATIC_LIBRARY_SUFFIX}"
        IMPORTED_LOCATION_DEBUG "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}yaml-cppd${CMAKE_STATIC_LIBRARY_SUFFIX}")
ELSE()
    SET_TARGET_PROPERTIES(yaml-cpp PROPERTIES IMPORTED_LOCATION
        "${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}yaml-cpp${CMAKE_STATIC_LIBRARY_SUFFIX}")
ENDIF()

SET_TARGET_PROPERTIES(yaml-cpp PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${YAML_CPP_INCLUDES}")
