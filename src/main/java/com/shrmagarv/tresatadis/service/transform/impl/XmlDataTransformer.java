package com.shrmagarv.tresatadis.service.transform.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.xml.XmlMapper;
import com.shrmagarv.tresatadis.service.transform.DataTransformer;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathFactory;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Implementation of DataTransformer for XML data
 * Handles transformation of XML files based on configuration
 */
@Service
public class XmlDataTransformer implements DataTransformer {
    
    private static final String TRANSFORMATION_TYPE = "XML";
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final XmlMapper xmlMapper = new XmlMapper();
    
    @Override
    public String getTransformationType() {
        return TRANSFORMATION_TYPE;
    }
    
    @Override
    public boolean canHandle(String transformationType) {
        return TRANSFORMATION_TYPE.equals(transformationType);
    }
    
    @Override
    public Resource transform(Resource data, String sourceFormat, String transformationConfig) throws Exception {
        if (!"XML".equalsIgnoreCase(sourceFormat)) {
            throw new IllegalArgumentException("This transformer only works with XML data");
        }
        
        // Parse the transformation config
        JsonNode configNode = objectMapper.readTree(transformationConfig);
        
        // Parse the XML file
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        DocumentBuilder builder = factory.newDocumentBuilder();
        Document document;
        try (InputStream is = data.getInputStream()) {
            document = builder.parse(is);
        }
        
        // Extract xpath expressions and transformations from config
        Map<String, String> elementMappings = new HashMap<>();
        List<String> elementsToRemove = new ArrayList<>();
        
        if (configNode.has("elementMappings")) {
            JsonNode mappings = configNode.get("elementMappings");
            mappings.fields().forEachRemaining(entry -> 
                elementMappings.put(entry.getKey(), entry.getValue().asText()));
        }
        
        if (configNode.has("elementsToRemove")) {
            JsonNode toRemove = configNode.get("elementsToRemove");
            toRemove.forEach(node -> elementsToRemove.add(node.asText()));
        }
        
        // Apply transformations
        XPathFactory xPathFactory = XPathFactory.newInstance();
        XPath xpath = xPathFactory.newXPath();
        
        // Handle element mappings (renames)
        for (Map.Entry<String, String> mapping : elementMappings.entrySet()) {
            String oldElementXPath = mapping.getKey();
            String newElementName = mapping.getValue();
            
            XPathExpression expr = xpath.compile(oldElementXPath);
            NodeList nodes = (NodeList) expr.evaluate(document, XPathConstants.NODESET);
            
            for (int i = 0; i < nodes.getLength(); i++) {
                Node node = nodes.item(i);
                if (node.getNodeType() == Node.ELEMENT_NODE) {
                    Element oldElement = (Element) node;
                    Element newElement = document.createElement(newElementName);
                    
                    // Copy all attributes
                    for (int j = 0; j < oldElement.getAttributes().getLength(); j++) {
                        Node attribute = oldElement.getAttributes().item(j);
                        newElement.setAttribute(attribute.getNodeName(), attribute.getNodeValue());
                    }
                    
                    // Move all child nodes to new element
                    while (oldElement.hasChildNodes()) {
                        newElement.appendChild(oldElement.getFirstChild());
                    }
                    
                    // Replace old element with new one
                    Node parent = oldElement.getParentNode();
                    parent.replaceChild(newElement, oldElement);
                }
            }
        }
        
        // Remove elements
        for (String removeXPath : elementsToRemove) {
            XPathExpression expr = xpath.compile(removeXPath);
            NodeList nodes = (NodeList) expr.evaluate(document, XPathConstants.NODESET);
            
            for (int i = nodes.getLength() - 1; i >= 0; i--) {
                Node node = nodes.item(i);
                if (node.getNodeType() == Node.ELEMENT_NODE) {
                    Node parent = node.getParentNode();
                    parent.removeChild(node);
                }
            }
        }
        
        // Write the transformed XML to output
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        TransformerFactory transformerFactory = TransformerFactory.newInstance();
        Transformer transformer = transformerFactory.newTransformer();
        DOMSource source = new DOMSource(document);
        StreamResult result = new StreamResult(outputStream);
        transformer.transform(source, result);
        
        return new ByteArrayResource(outputStream.toByteArray());
    }
}
