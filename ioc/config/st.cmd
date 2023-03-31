
cd "$(TOP)"

epicsEnvSet("EPICS_CA_REPEATER_PORT","7065")
epicsEnvSet("EPICS_CA_SERVER_PORT","7064")

dbLoadDatabase "dbd/ioc.dbd"
ioc_registerRecordDeviceDriver(pdbbase)

URLDriverConfig("EXAMPLE.CAM", 0, 0)

# NDPvaConfigure(portName, queueSize, blockingCallbacks, NDArrayPort, NDArrayAddr, pvName, maxMemory, priority, stackSize)
NDPvaConfigure("EXAMPLE.PVA", 2, 0, "EXAMPLE.CAM", 0, "EXAMPLE:IMAGE", 0, 0, 0)
startPVAServer

# instantiate Database records for Url Detector
dbLoadRecords("URLDriver.template","P=EXAMPLE, R=:CAM:, PORT=EXAMPLE.CAM, TIMEOUT=1, ADDR=0")
dbLoadRecords("NDPva.template", "P=EXAMPLE, R=:PVA:, PORT=EXAMPLE.PVA, ADDR=0, TIMEOUT=1, NDARRAY_PORT=EXAMPLE.CAM, NDARRAY_ADR=0, ENABLED=1")

# start IOC shell
iocInit

# poke some records
dbpf "EXAMPLE:CAM:AcquirePeriod", "0.1"

