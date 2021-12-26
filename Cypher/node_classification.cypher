--MATCH (n:BISVClass) DETACH DELETE n
--MATCH (n:UnknownBISVClass) DETACH DELETE n
--CALL gds.graph.drop('BISVClassGraph')
--CALL gds.beta.model.drop('nc-model')



CREATE
  (:BISVClass {color: 'Gold', sizePerStory: [15.5, 23.6, 33.1], class: 0}),
  (:BISVClass {color: 'Red', sizePerStory: [15.5, 23.6, 100.0], class: 0}),
  (:BISVClass {color: 'Blue', sizePerStory: [11.3, 35.1, 22.0], class: 0}),
  (:BISVClass {color: 'Green', sizePerStory: [23.2, 55.1, 0.0], class: 1}),
  (:BISVClass {color: 'Gray', sizePerStory: [34.3, 24.0, 0.0],  class: 1}),
  (:BISVClass {color: 'Black', sizePerStory: [71.66, 55.0, 0.0], class: 1}),
  (:BISVClass {color: 'White', sizePerStory: [11.1, 111.0, 0.0], class: 1}),
  (:BISVClass {color: 'Teal', sizePerStory: [80.8, 0.0, 0.0], class: 2}),
  (:BISVClass {color: 'Beige', sizePerStory: [106.2, 0.0, 0.0], class: 2}),
  (:BISVClass {color: 'Magenta', sizePerStory: [99.9, 0.0, 0.0], class: 2}),
  (:BISVClass {color: 'Purple', sizePerStory: [56.5, 0.0, 0.0], class: 2}),
  (:UnknownBISVClass {color: 'Pink', sizePerStory: [23.2, 55.1, 56.1]}),
  (:UnknownBISVClass {color: 'Tan', sizePerStory: [22.32, 102.0, 0.0]}),
  (:UnknownBISVClass {color: 'Yellow', sizePerStory: [39.0, 0.0, 0.0]});


CALL gds.graph.create('BISVClassGraph', {
    BISVClass: { properties: ['sizePerStory', 'class'] },
    UnknownBISVClass: { properties: 'sizePerStory' }
  },
  '*'
)


CALL gds.alpha.ml.nodeClassification.train.estimate('BISVClassGraph', {
  nodeLabels: ['BISVClass'],
  modelName: 'nc-model',
  featureProperties: ['sizePerStory'],
  targetProperty: 'class',
  randomSeed: 2,
  holdoutFraction: 0.2,
  validationFolds: 5,
  metrics: [ 'F1_WEIGHTED' ],
  params: [
    {penalty: 0.0625},
    {penalty: 0.5},
    {penalty: 1.0},
    {penalty: 4.0}
  ]
})
YIELD bytesMin, bytesMax, requiredMemory


CALL gds.alpha.ml.nodeClassification.train('BISVClassGraph', {
  nodeLabels: ['BISVClass'],
  modelName: 'nc-model',
  featureProperties: ['sizePerStory'],
  targetProperty: 'class',
  randomSeed: 2,
  holdoutFraction: 0.2,
  validationFolds: 5,
  metrics: [ 'F1_WEIGHTED' ],
  params: [
    {penalty: 0.0625},
    {penalty: 0.5},
    {penalty: 1.0},
    {penalty: 4.0}
  ]
}) YIELD modelInfo
RETURN
  {penalty: modelInfo.bestParameters.penalty} AS winningModel,
  modelInfo.metrics.F1_WEIGHTED.outerTrain AS trainGraphScore,
  modelInfo.metrics.F1_WEIGHTED.test AS testGraphScore


CALL gds.alpha.ml.nodeClassification.predict.stream('BISVClassGraph', {
  nodeLabels: ['BISVClass', 'UnknownBISVClass'],
  modelName: 'nc-model',
  includePredictedProbabilities: true
}) YIELD nodeId, predictedClass, predictedProbabilities
WITH gds.util.asNode(nodeId) AS BISVClassNode, predictedClass, predictedProbabilities
WHERE BISVClassNode:UnknownBISVClass
RETURN
  BISVClassNode.color AS classifiedBISVClass,
  predictedClass,
  floor(predictedProbabilities[predictedClass] * 100) AS confidence
  ORDER BY classifiedBISVClass


CALL gds.alpha.ml.nodeClassification.predict.mutate('BISVClassGraph', {
  nodeLabels: ['BISVClass', 'UnknownBISVClass'],
  modelName: 'nc-model',
  mutateProperty: 'predictedClass',
  predictedProbabilityProperty: 'predictedProbabilities'
}) YIELD nodePropertiesWritten


CALL gds.graph.streamNodeProperties(
  'BISVClassGraph', ['predictedProbabilities', 'predictedClass'], ['UnknownBISVClass']
) YIELD nodeId, nodeProperty, propertyValue
RETURN gds.util.asNode(nodeId).color AS classifiedBISVClass, nodeProperty, propertyValue
  ORDER BY classifiedBISVClass, nodeProperty



CALL gds.alpha.ml.nodeClassification.predict.write('BISVClassGraph', {
  nodeLabels: ['BISVClass', 'UnknownBISVClass'],
  modelName: 'nc-model',
  writeProperty: 'predictedClass',
  predictedProbabilityProperty: 'predictedProbabilities'
}) YIELD nodePropertiesWritten



MATCH (BISVClass:UnknownBISVClass)
RETURN BISVClass.color AS classifiedBISVClass, BISVClass.predictedClass AS predictedClass, BISVClass.predictedProbabilities AS predictedProbabilities
