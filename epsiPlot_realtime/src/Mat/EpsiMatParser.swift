import Foundation

class EpsiMatParser
{
    func readFile(model: Model)
    {
        let mat = MatData(fileUrl: model.currentFileUrl!)

        model.epsi.time_s = transpose(mat: mat.getMatrixDouble2(name: "epsi.time_s"))
        model.epsi.t1_volt = transpose(mat: mat.getMatrixDouble2(name: "epsi.t1_volt"))
        model.epsi.t2_volt = transpose(mat: mat.getMatrixDouble2(name: "epsi.t2_volt"))
        model.epsi.s1_volt = transpose(mat: mat.getMatrixDouble2(name: "epsi.s1_volt"))
        model.epsi.s2_volt = transpose(mat: mat.getMatrixDouble2(name: "epsi.s2_volt"))
        model.epsi.a1_g = transpose(mat: mat.getMatrixDouble2(name: "epsi.a1_g"))
        model.epsi.a2_g = transpose(mat: mat.getMatrixDouble2(name: "epsi.a2_g"))
        model.epsi.a3_g = transpose(mat: mat.getMatrixDouble2(name: "epsi.a3_g"))

        model.ctd.time_s = transpose(mat: mat.getMatrixDouble2(name: "ctd.time_s"))
        model.ctd.P = transpose(mat: mat.getMatrixDouble2(name: "ctd.P"))
        model.ctd.T = transpose(mat: mat.getMatrixDouble2(name: "ctd.T"))
        model.ctd.S = transpose(mat: mat.getMatrixDouble2(name: "ctd.S"))
        model.ctd.z = transpose(mat: mat.getMatrixDouble2(name: "ctd.z"))

        model.resetTimeWindow()
        model.calculateDerivedData()
    }

    func transpose(mat: [[Double]]) -> [Double]
    {
        assert(mat[0].count == 1)
        var result = Array(repeating: 0.0, count: mat.count)
        for i in 0..<mat.count {
            result[i] = mat[i][0]
        }
        return result
    }
}

