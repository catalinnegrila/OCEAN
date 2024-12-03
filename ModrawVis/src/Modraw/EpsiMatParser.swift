import Foundation
import ModrawLib

class EpsiMatParser
{
    init(model: Model, fileUrl: URL) throws
    {
        let mat = try MatParser(fileUrl: fileUrl)
            
        model.d.epsi_blocks = [EpsiModelData()]
        let epsi = model.d.epsi_blocks.first!
        epsi.time_s.data = mat.getMatrixNumeric1(name: "epsi.time_s")
        epsi.t1_volt.data = mat.getMatrixNumeric1(name: "epsi.t1_volt")
        epsi.t2_volt.data = mat.getMatrixNumeric1(name: "epsi.t2_volt")
        epsi.s1_volt.data = mat.getMatrixNumeric1(name: "epsi.s1_volt")
        epsi.s2_volt.data =  mat.getMatrixNumeric1(name: "epsi.s2_volt")
        epsi.a1_g.data = mat.getMatrixNumeric1(name: "epsi.a1_g")
        epsi.a2_g.data = mat.getMatrixNumeric1(name: "epsi.a2_g")
        epsi.a3_g.data = mat.getMatrixNumeric1(name: "epsi.a3_g")

        model.d.ctd_blocks = [CtdModelData()]
        let ctd = model.d.ctd_blocks.first!
        ctd.time_s.data = mat.getMatrixNumeric1(name: "ctd.time_s")
        ctd.P.data = mat.getMatrixNumeric1(name: "ctd.P")
        ctd.T.data = mat.getMatrixNumeric1(name: "ctd.T")
        ctd.S.data = mat.getMatrixNumeric1(name: "ctd.S")
        ctd.z.data = mat.getMatrixNumeric1(name: "ctd.z")
        model.d.isUpdated = true
    }
}

