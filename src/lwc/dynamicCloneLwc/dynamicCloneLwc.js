/**
 * Author: Kevin Antonioli (braveitnow@pm.me)
 * Created: 2/27/2023
 *
 * Description: JS for Dynamic Clone LWC
 *
 * Revisions:
 * Date : Name : Notes
 */
import { api, wire } from "lwc";
import LightningModal from "lightning/modal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// import apex controller methods:
import getChildRelInfo from "@salesforce/apex/DynamicCloneController.getChildRelInfo";
import performDynamicClone from "@salesforce/apex/DynamicCloneController.performDynamicClone";

export default class MyModal extends LightningModal {
  @api hasLoaded = false;
  @api recordId;
  @api childRelationshipNames = "";
  childInfos;
  cloneButtonDisabled = false;
  selectedObjs = new Set();

  get theRecordId() {
    return this.recordId;
  }
  get childRelationships() {
    return this.childRelationshipNames;
  }

  // get child record info via calling apex controller method:
  @wire(getChildRelInfo, {
    parentRecordId: "$theRecordId",
    childRelationshipNames: "$childRelationships"
  })
  wiredResults(result) {
    console.log("error", result.error);
    console.log("result.data", result.data);
    this.cloneButtonDisabled = true;
    if (result.data) {
      this.hasLoaded = true;
      this.childInfos = result.data;
    } else if (result.error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error retrieving child object names",
          message: error.body.message,
          variant: "error"
        })
      );
    }
  }

  /**
   * @description -> append user-selected child objects to set
   * @param event -> click event passed in from clicking child object checkboxes
   */
  appendToSelected(event) {
    if (event.detail.checked) {
      this.selectedObjs.add(event.target.dataset.relname);
    } else {
      this.selectedObjs.delete(event.target.dataset.relname);
    }
    this.cloneButtonDisabled = this.selectedObjs.size === 0 ? true : false;
  }

  /**
   * @description -> clone records for child objects user selected in Dynamic Clone modal
   * @param null;
   */
  cloneSelectedRecords() {
    this.hasLoaded = false;
    const selectedObjsStr = [...this.selectedObjs].join(",");
    performDynamicClone({
      parentRecordId: this.recordId,
      selectedObjsStr: selectedObjsStr
    })
      .then((result) => {
        let title = result.numOfRecords <= 200 ? "Success!" : "Pending";
        let message =
          result.numOfRecords <= 200
            ? "Successfully cloned " +
              result.numOfRecords +
              " records for selected objects!"
            : "Large clone of " +
              result.numOfRecords +
              " records in progress. Should be done within 60 seconds. JobId: " +
              result.jobId;
        let variant = result.numOfRecords <= 200 ? "success" : "info";
        this.dispatchEvent(
          new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
          })
        );
        this.hasLoaded = true;
      })
      .catch((error) => {
        console.log("-------error-------------" + error);
        console.log(error);
        this.hasLoaded = true;
      });
  }
}