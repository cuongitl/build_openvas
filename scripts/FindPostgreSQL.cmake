# Distributed under the OSI-approved BSD 3-Clause License.
# See accompanying file Copyright.txt or
# https://cmake.org/licensing for details.

#[=======================================================================[.rst:
FindPostgreSQL
--------------

Find the PostgreSQL installation (PostgreSQL 16 or 17 only).

IMPORTED Targets
^^^^^^^^^^^^^^^^

This module defines :prop_tgt:`IMPORTED` target ``PostgreSQL::PostgreSQL``
if PostgreSQL has been found.

Result Variables
^^^^^^^^^^^^^^^^

``PostgreSQL_FOUND``
  True if PostgreSQL is found and version is 16.x or 17.x
``PostgreSQL_LIBRARIES``
  the PostgreSQL libraries needed for linking
``PostgreSQL_INCLUDE_DIRS``
  the directories of the PostgreSQL headers
``PostgreSQL_LIBRARY_DIRS``
  the link directories for PostgreSQL libraries
``PostgreSQL_VERSION_STRING``
  the version of PostgreSQL found
#]=======================================================================]

# ---------------------------------------------------------------------------
# Supported PostgreSQL versions (prefer newer first)
# ---------------------------------------------------------------------------

set(PostgreSQL_KNOWN_VERSIONS
  "17"
  "16"
)

# ---------------------------------------------------------------------------
# Paths and environment
# ---------------------------------------------------------------------------

set(PostgreSQL_ROOT_DIRECTORIES
  ENV PostgreSQL_ROOT
  ${PostgreSQL_ROOT}
)

# ---------------------------------------------------------------------------
# Version-specific search suffixes
# ---------------------------------------------------------------------------

foreach(suffix ${PostgreSQL_KNOWN_VERSIONS})
  if(WIN32)
    list(APPEND PostgreSQL_LIBRARY_ADDITIONAL_SEARCH_SUFFIXES
      "PostgreSQL/${suffix}/lib")
    list(APPEND PostgreSQL_INCLUDE_ADDITIONAL_SEARCH_SUFFIXES
      "PostgreSQL/${suffix}/include")
    list(APPEND PostgreSQL_TYPE_ADDITIONAL_SEARCH_SUFFIXES
      "PostgreSQL/${suffix}/include/server")
  endif()

  if(UNIX)
    list(APPEND PostgreSQL_LIBRARY_ADDITIONAL_SEARCH_SUFFIXES
      "postgresql/${suffix}"
      "pgsql-${suffix}/lib")
    list(APPEND PostgreSQL_INCLUDE_ADDITIONAL_SEARCH_SUFFIXES
      "postgresql/${suffix}"
      "pgsql-${suffix}/include")
    list(APPEND PostgreSQL_TYPE_ADDITIONAL_SEARCH_SUFFIXES
      "postgresql/${suffix}/server"
      "pgsql-${suffix}/include/server")
  endif()
endforeach()

# ---------------------------------------------------------------------------
# Includes
# ---------------------------------------------------------------------------

find_path(PostgreSQL_INCLUDE_DIR
  NAMES libpq-fe.h
  PATHS ${PostgreSQL_ROOT_DIRECTORIES}
  PATH_SUFFIXES
    include
    postgresql
    ${PostgreSQL_INCLUDE_ADDITIONAL_SEARCH_SUFFIXES}
)

find_path(PostgreSQL_TYPE_INCLUDE_DIR
  NAMES catalog/pg_type.h
  PATHS ${PostgreSQL_ROOT_DIRECTORIES}
  PATH_SUFFIXES
    include/server
    postgresql/server
    ${PostgreSQL_TYPE_ADDITIONAL_SEARCH_SUFFIXES}
)

# ---------------------------------------------------------------------------
# Libraries
# ---------------------------------------------------------------------------

set(PostgreSQL_LIBRARY_TO_FIND pq)
if(WIN32)
  set(PostgreSQL_LIBRARY_TO_FIND libpq)
endif()

function(__postgresql_find_library _name)
  find_library(${_name}
    NAMES ${ARGN}
    PATHS ${PostgreSQL_ROOT_DIRECTORIES}
    PATH_SUFFIXES
      lib
      ${PostgreSQL_LIBRARY_ADDITIONAL_SEARCH_SUFFIXES}
  )
endfunction()

if(PostgreSQL_LIBRARY)
  set(PostgreSQL_LIBRARIES "${PostgreSQL_LIBRARY}")
  get_filename_component(PostgreSQL_LIBRARY_DIR
    "${PostgreSQL_LIBRARY}" PATH)
else()
  __postgresql_find_library(PostgreSQL_LIBRARY_RELEASE
    ${PostgreSQL_LIBRARY_TO_FIND})
  __postgresql_find_library(PostgreSQL_LIBRARY_DEBUG
    ${PostgreSQL_LIBRARY_TO_FIND}d)

  include("${CMAKE_ROOT}/Modules/SelectLibraryConfigurations.cmake")
  select_library_configurations(PostgreSQL)

  if(PostgreSQL_LIBRARY_RELEASE)
    get_filename_component(PostgreSQL_LIBRARY_DIR
      "${PostgreSQL_LIBRARY_RELEASE}" PATH)
  elseif(PostgreSQL_LIBRARY_DEBUG)
    get_filename_component(PostgreSQL_LIBRARY_DIR
      "${PostgreSQL_LIBRARY_DEBUG}" PATH)
  else()
    set(PostgreSQL_LIBRARY_DIR "")
  endif()
endif()

# ---------------------------------------------------------------------------
# Version detection
# ---------------------------------------------------------------------------

if(PostgreSQL_INCLUDE_DIR)
  file(GLOB _PG_CONFIG_HEADERS
    "${PostgreSQL_INCLUDE_DIR}/pg_config*.h")

  foreach(_hdr ${_PG_CONFIG_HEADERS})
    file(STRINGS "${_hdr}" _ver
      REGEX "^#define[ \t]+PG_VERSION_NUM[ \t]+[0-9]+")
    if(_ver)
      string(REGEX REPLACE
        "^#define[ \t]+PG_VERSION_NUM[ \t]+([0-9]+).*"
        "\\1" _PG_VERSION_NUM "${_ver}")
      break()
    endif()
  endforeach()

  if(_PG_VERSION_NUM)
    math(EXPR _PG_MAJOR "${_PG_VERSION_NUM} / 10000")
    math(EXPR _PG_MINOR "${_PG_VERSION_NUM} % 10000")
    set(PostgreSQL_VERSION_STRING
      "${_PG_MAJOR}.${_PG_MINOR}")
  endif()
endif()

# ---------------------------------------------------------------------------
# HARD REQUIRE PostgreSQL 16 or 17
# ---------------------------------------------------------------------------

if(NOT PostgreSQL_VERSION_STRING)
  message(FATAL_ERROR
    "PostgreSQL 16 or 17 is required, but the version could not be determined")
endif()

if(NOT PostgreSQL_VERSION_STRING MATCHES "^(16|17)(\\.|$)")
  message(FATAL_ERROR
    "PostgreSQL 16 or 17 is required, but found PostgreSQL ${PostgreSQL_VERSION_STRING}")
endif()

# ---------------------------------------------------------------------------
# Final package handling
# ---------------------------------------------------------------------------

include("${CMAKE_ROOT}/Modules/FindPackageHandleStandardArgs.cmake")
find_package_handle_standard_args(PostgreSQL
  REQUIRED_VARS
    PostgreSQL_LIBRARY
    PostgreSQL_INCLUDE_DIR
    PostgreSQL_TYPE_INCLUDE_DIR
  VERSION_VAR PostgreSQL_VERSION_STRING
  FAIL_MESSAGE "PostgreSQL 16 or 17 is required"
)

set(PostgreSQL_FOUND ${POSTGRESQL_FOUND})

# ---------------------------------------------------------------------------
# Imported target
# ---------------------------------------------------------------------------

if(PostgreSQL_FOUND AND NOT TARGET PostgreSQL::PostgreSQL)
  add_library(PostgreSQL::PostgreSQL UNKNOWN IMPORTED)
  set_target_properties(PostgreSQL::PostgreSQL PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES
      "${PostgreSQL_INCLUDE_DIR};${PostgreSQL_TYPE_INCLUDE_DIR}"
    IMPORTED_LOCATION
      "${PostgreSQL_LIBRARY}"
  )
endif()

set(PostgreSQL_INCLUDE_DIRS
  ${PostgreSQL_INCLUDE_DIR}
  ${PostgreSQL_TYPE_INCLUDE_DIR})

set(PostgreSQL_LIBRARY_DIRS
  ${PostgreSQL_LIBRARY_DIR})

mark_as_advanced(
  PostgreSQL_INCLUDE_DIR
  PostgreSQL_TYPE_INCLUDE_DIR
  PostgreSQL_LIBRARY_RELEASE
  PostgreSQL_LIBRARY_DEBUG
)

