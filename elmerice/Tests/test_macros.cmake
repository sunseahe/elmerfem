MACRO(ADD_ELMER_LABEL test_name label_string)
  SET_PROPERTY(TEST ${test_name} APPEND PROPERTY LABELS ${label_string})
ENDMACRO()

MACRO(ADD_ELMERICE_TEST test_name)
  ADD_TEST(NAME ${test_name}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMAND ${CMAKE_COMMAND}
      -DELMERGRID_BIN=${ELMERGRID_BIN}
      -DELMERSOLVER_BIN=${ELMERSOLVER_BIN}
      -DTEST_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}
      -DPROJECT_SOURCE_DIR=${PROJECT_SOURCE_DIR}
      -DBINARY_DIR=${CMAKE_BINARY_DIR}
      -DELMERSOLVER_HOME=${ELMER_SOLVER_HOME}
      -DSHLEXT=${SHL_EXTENSION}
      -DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}
      -DMPIEXEC=${MPIEXEC}
      -DMPIEXEC_NUMPROC_FLAG=${MPIEXEC_NUMPROC_FLAG}
      -DMPIEXEC_PREFLAGS=${MPIEXEC_PREFLAGS}
      -DMPIEXEC_POSTFLAGS=${MPIEXEC_POSTFLAGS}
      -DWITH_MPI=${WITH_MPI}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/runTest.cmake)
    SET_TESTS_PROPERTIES(${test_name} PROPERTIES LABELS "elmerice")
ENDMACRO()

MACRO(ADD_ELMERICETEST_MODULE test_name module_name file_name)
  IF(APPLE)
    SET(CMAKE_SHARED_MODULE_SUFFIX ".dylib")
  ENDIF(APPLE)
  SET(ELMERICETEST_CMAKE_NAME "${test_name}_${module_name}")
  ADD_LIBRARY(${ELMERICETEST_CMAKE_NAME} MODULE ${file_name})
  SET_TARGET_PROPERTIES(${ELMERICETEST_CMAKE_NAME}
    PROPERTIES PREFIX "")
  TARGET_LINK_LIBRARIES(${ELMERICETEST_CMAKE_NAME}
    elmersolver)
  SET_TARGET_PROPERTIES(${ELMERICETEST_CMAKE_NAME}
    PROPERTIES OUTPUT_NAME ${module_name} LINKER_LANGUAGE Fortran)
  TARGET_LINK_LIBRARIES(${ELMERICETEST_CMAKE_NAME} elmersolver)
  IF(WITH_MPI)
    ADD_DEPENDENCIES(${ELMERICETEST_CMAKE_NAME} 
      elmersolver ElmerSolver_mpi ElmerGrid)
  ELSE()
    ADD_DEPENDENCIES(${ELMERICETEST_CMAKE_NAME} 
      elmersolver ElmerSolver ElmerGrid)
  ENDIF()
  UNSET(ELMERICETEST_CMAKE_NAME)
ENDMACRO()

MACRO(RUN_ELMERICE_TEST)
  MESSAGE(STATUS "BINARY_DIR = ${BINARY_DIR}")
  FILE(REMOVE TEST.PASSED)
  #Optional arguments like WITH_MPI
  SET(LIST_VAR "${ARGN}")
  IF("LIST_VAR" STREQUAL "")
    EXECUTE_PROCESS(COMMAND ${ELMERSOLVER_BIN}
      OUTPUT_FILE "test-stdout.log"
      ERROR_FILE "test-stderr.log"
      OUTPUT_VARIABLE TESTOUTPUT)
  ELSE()
     IF("${LIST_VAR}" STREQUAL WITH_MPI)
       SET(N "${NPROCS}")
         IF("N" STREQUAL "")
	   MESSAGE( FATAL_ERROR "Test failed:variable <NPROC> not defined. Set <NPROC> in runTes.cmake")
         ELSE()
	   EXECUTE_PROCESS(COMMAND ${MPIEXEC} ${MPIEXEC_NUMPROC_FLAG} ${N} ${MPIEXEC_PREFLAGS} ${ELMERSOLVER_BIN} ${MPIEXEC_POSTFLAGS}
             OUTPUT_FILE "test-stdout.log"
             ERROR_FILE "test-stderr.log"
             OUTPUT_VARIABLE TESTOUTPUT)
         ENDIF()
       ENDIF()
  ENDIF()

  MESSAGE(STATUS "testoutput.........: ${TESTOUTPUT}")

  IF(NPROCS GREATER "1")
    FILE(READ "TEST.PASSED_${NPROCS}" RES)
  ELSE()
    FILE(READ "TEST.PASSED" RES)
  ENDIF()
  IF(NOT RES EQUAL "1")
    MESSAGE(FATAL_ERROR "Test failed")
  ENDIF()
ENDMACRO()

MACRO(EXECUTE_ELMER_SOLVER SIFNAME)
  SET(ENV{ELMER_HOME} "${BINARY_DIR}/fem/src")
  SET(ENV{ELMER_LIB} "${BINARY_DIR}/fem/src/modules")
  EXECUTE_PROCESS(COMMAND ${ELMERSOLVER_BIN} ${SIFNAME} OUTPUT_FILE "${SIFNAME}-stdout.log"
    ERROR_FILE "${SIFNAME}-stderr.log")
ENDMACRO()
